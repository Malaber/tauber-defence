import Foundation

public struct GameSimulation: Sendable {
    public private(set) var session: GameSession
    public private(set) var events: [GameEvent]

    private let originalLevel: LevelDefinition
    private let originalConfiguration: SimulationConfiguration
    private var accumulator: Double
    private var scheduledSpawns: [ScheduledSpawn]
    private var pendingAttacks: [PendingAttack]
    private var nextPigeonID: Int
    private var nextDefenseID: Int
    private var fledThisStep: Int

    public init(
        level: LevelDefinition = .marketplace,
        configuration: SimulationConfiguration = .init()
    ) {
        self.session = GameSession(level: level, configuration: configuration)
        self.events = []
        self.originalLevel = level
        self.originalConfiguration = configuration
        self.accumulator = 0
        self.scheduledSpawns = []
        self.pendingAttacks = []
        self.nextPigeonID = 1
        self.nextDefenseID = 1
        self.fledThisStep = 0
    }

    @discardableResult
    public mutating func startNextWave() -> Bool {
        guard !session.isPaused,
              session.phase == .preparing || session.phase == .waveComplete,
              let wave = session.nextWave else {
            return false
        }

        transitionPhase(to: .waveRunning)
        session.currentWaveNumber = wave.number
        session.waveElapsedTime = 0
        accumulator = 0
        scheduledSpawns = Self.makeSpawnSchedule(for: wave)
        pendingAttacks.removeAll(keepingCapacity: true)
        events.append(.waveStarted(number: wave.number))
        spawnPigeonsThatAreDue()
        return true
    }

    @discardableResult
    public mutating func purchaseDefense(
        _ type: DefenseType,
        at buildSpotID: Int
    ) throws -> Int {
        guard !session.isGameOver else { throw PurchaseError.gameEnded }
        guard let spotIndex = session.buildSpots.firstIndex(where: { $0.id == buildSpotID }) else {
            throw PurchaseError.invalidBuildSpot(buildSpotID)
        }
        guard !session.buildSpots[spotIndex].isOccupied else {
            throw PurchaseError.buildSpotOccupied(buildSpotID)
        }
        guard session.money >= type.cost else {
            throw PurchaseError.insufficientFunds(required: type.cost, available: session.money)
        }

        let defenseID = nextDefenseID
        nextDefenseID += 1
        let defense = Defense(
            id: defenseID,
            type: type,
            buildSpotID: buildSpotID,
            position: session.buildSpots[spotIndex].position
        )
        session.defenses.append(defense)
        session.buildSpots[spotIndex].occupiedByDefenseID = defenseID
        session.money -= type.cost
        events.append(
            .defensePurchased(
                id: defenseID,
                type: type,
                buildSpotID: buildSpotID,
                cost: type.cost
            )
        )
        events.append(
            .moneyChanged(delta: -type.cost, total: session.money, reason: .defensePurchase)
        )
        return defenseID
    }

    public mutating func update(deltaTime: Double) {
        precondition(deltaTime.isFinite && deltaTime >= 0, "Delta time must be finite and non-negative")
        guard deltaTime > 0, !session.isPaused, session.phase == .waveRunning else { return }

        accumulator += deltaTime
        let step = session.configuration.fixedTimeStep
        while accumulator + 1e-12 >= step, session.phase == .waveRunning {
            simulateStep(deltaTime: step)
            accumulator -= step
            if accumulator < 0, accumulator > -1e-10 {
                accumulator = 0
            }
        }
        if session.phase != .waveRunning {
            accumulator = 0
        }
    }

    public mutating func setPaused(_ isPaused: Bool) {
        guard session.isPaused != isPaused, !session.isGameOver else { return }
        session.isPaused = isPaused
        events.append(.pauseChanged(isPaused: isPaused))
    }

    public mutating func togglePause() {
        setPaused(!session.isPaused)
    }

    public mutating func reset() {
        session = GameSession(level: originalLevel, configuration: originalConfiguration)
        accumulator = 0
        scheduledSpawns.removeAll(keepingCapacity: true)
        pendingAttacks.removeAll(keepingCapacity: true)
        nextPigeonID = 1
        nextDefenseID = 1
        fledThisStep = 0
        events = [.sessionReset]
    }

    public mutating func consumeEvents() -> [GameEvent] {
        defer { events.removeAll(keepingCapacity: true) }
        return events
    }
}

private extension GameSimulation {
    struct ScheduledSpawn: Sendable {
        let time: Double
        let order: Int
        let type: PigeonType
    }

    struct PendingAttack: Sendable {
        let impactTime: Double
        let defenseID: Int
        let pigeonID: Int
        let pressure: Double
    }

    static func makeSpawnSchedule(for wave: WaveDefinition) -> [ScheduledSpawn] {
        var result: [ScheduledSpawn] = []
        var groupStartTime = 0.0
        var spawnOrder = 0

        for group in wave.groups {
            groupStartTime += group.initialDelay
            for index in 0..<group.count {
                result.append(
                    ScheduledSpawn(
                        time: groupStartTime + (Double(index) * group.spawnInterval),
                        order: spawnOrder,
                        type: group.pigeonType
                    )
                )
                spawnOrder += 1
            }
            if group.count > 0 {
                groupStartTime += Double(group.count) * group.spawnInterval
            }
        }

        return result.sorted { lhs, rhs in
            if lhs.time == rhs.time { return lhs.order < rhs.order }
            return lhs.time < rhs.time
        }
    }

    mutating func simulateStep(deltaTime: Double) {
        fledThisStep = 0
        session.simulationTime += deltaTime
        session.waveElapsedTime += deltaTime
        refreshDefenseTargetsAndCooldowns(deltaTime: deltaTime)
        advanceExistingPigeons(deltaTime: deltaTime)
        guard session.phase == .waveRunning else { return }

        spawnPigeonsThatAreDue()
        resolvePendingAttacks()
        runReadyDefenses()

        if fledThisStep >= 2 {
            events.append(.shooCombo(count: fledThisStep))
        }

        session.pigeons.removeAll { $0.state == .removed }
        completeWaveIfPossible()
    }

    mutating func refreshDefenseTargetsAndCooldowns(deltaTime: Double) {
        for index in session.defenses.indices {
            let defenseID = session.defenses[index].id
            session.defenses[index].cooldownRemaining = max(
                0,
                session.defenses[index].cooldownRemaining - deltaTime
            )
            let activeTargetIDs = Set(
                session.pigeons.filter { $0.isTargetable }.map(\.id)
            )
            var targetIDs = session.defenses[index].cooldownRemaining > 0
                ? session.defenses[index].targetPigeonIDs.filter { activeTargetIDs.contains($0) }
                : []
            let pendingTargetIDs = pendingAttacks
                .filter { $0.defenseID == defenseID }
                .map(\.pigeonID)
            for targetID in pendingTargetIDs where !targetIDs.contains(targetID) {
                targetIDs.append(targetID)
            }
            session.defenses[index].targetPigeonIDs = targetIDs
        }
    }

    mutating func advanceExistingPigeons(deltaTime: Double) {
        for index in session.pigeons.indices {
            var pigeon = session.pigeons[index]
            pigeon.stateElapsedTime += deltaTime

            switch pigeon.state {
            case .spawning:
                transitionPigeon(&pigeon, to: .moving)

            case .moving, .alert, .panicking:
                let speed = pigeon.baseSpeed * pigeon.speedMultiplier(at: session.simulationTime)
                pigeon.distanceAlongPath += speed * deltaTime
                pigeon.position = session.level.path.position(atDistance: pigeon.distanceAlongPath)
                if pigeon.distanceAlongPath + 1e-12 >= session.level.path.totalLength {
                    pigeon.distanceAlongPath = session.level.path.totalLength
                    pigeon.position = session.level.path.end
                    transitionPigeon(&pigeon, to: .reachedTarget)
                    handleArrival(of: pigeon)
                }

            case .fleeing:
                let progress = min(
                    pigeon.stateElapsedTime / session.configuration.fleeDuration,
                    1
                )
                pigeon.flightHeight = session.configuration.fleeHeight * progress
                if progress >= 1 {
                    transitionPigeon(&pigeon, to: .removed)
                    events.append(.pigeonRemoved(id: pigeon.id))
                }

            case .reachedTarget:
                if pigeon.stateElapsedTime >= session.configuration.reachedTargetRemovalDelay {
                    transitionPigeon(&pigeon, to: .removed)
                    events.append(.pigeonRemoved(id: pigeon.id))
                }

            case .removed:
                break
            }

            session.pigeons[index] = pigeon
            if session.phase == .defeat { break }
        }
    }

    mutating func spawnPigeonsThatAreDue() {
        while let nextSpawn = scheduledSpawns.first,
              nextSpawn.time <= session.waveElapsedTime + 1e-12 {
            scheduledSpawns.removeFirst()
            let pigeon = Pigeon(
                id: nextPigeonID,
                type: nextSpawn.type,
                position: session.level.path.start
            )
            nextPigeonID += 1
            session.pigeons.append(pigeon)
            events.append(
                .pigeonSpawned(id: pigeon.id, type: pigeon.type, position: pigeon.position)
            )
        }
    }

    mutating func resolvePendingAttacks() {
        let dueAttacks = pendingAttacks.filter {
            $0.impactTime <= session.simulationTime + 1e-12
        }
        pendingAttacks.removeAll {
            $0.impactTime <= session.simulationTime + 1e-12
        }

        for attack in dueAttacks.sorted(by: Self.pendingAttackOrder) {
            applyPressure(
                attack.pressure,
                toPigeonID: attack.pigeonID,
                fromDefenseID: attack.defenseID
            )
        }
    }

    static func pendingAttackOrder(_ lhs: PendingAttack, _ rhs: PendingAttack) -> Bool {
        if lhs.impactTime == rhs.impactTime {
            if lhs.defenseID == rhs.defenseID { return lhs.pigeonID < rhs.pigeonID }
            return lhs.defenseID < rhs.defenseID
        }
        return lhs.impactTime < rhs.impactTime
    }

    mutating func runReadyDefenses() {
        for defenseIndex in session.defenses.indices {
            guard session.defenses[defenseIndex].cooldownRemaining <= 1e-12 else { continue }

            switch session.defenses[defenseIndex].type {
            case .plasticOwl:
                firePlasticOwl(at: defenseIndex)
            case .sprinkler:
                fireSprinkler(at: defenseIndex)
            case .falconer:
                fireFalconer(at: defenseIndex)
            }
        }
    }

    mutating func firePlasticOwl(at defenseIndex: Int) {
        let defense = session.defenses[defenseIndex]
        guard let targetID = nearestTargetID(for: defense) else { return }
        recordDefenseFire(at: defenseIndex, targetIDs: [targetID])
        applyPressure(
            defense.type.pressure,
            toPigeonID: targetID,
            fromDefenseID: defense.id
        )
    }

    mutating func fireSprinkler(at defenseIndex: Int) {
        let defense = session.defenses[defenseIndex]
        let targetIDs = targets(inRangeOf: defense).map(\.id)
        guard !targetIDs.isEmpty else { return }
        recordDefenseFire(at: defenseIndex, targetIDs: targetIDs)

        for targetID in targetIDs {
            applySlow(toPigeonID: targetID)
            applyPressure(
                defense.type.pressure,
                toPigeonID: targetID,
                fromDefenseID: defense.id
            )
        }
    }

    mutating func fireFalconer(at defenseIndex: Int) {
        let defense = session.defenses[defenseIndex]
        guard let targetID = nearestTargetID(for: defense) else { return }
        recordDefenseFire(at: defenseIndex, targetIDs: [targetID])
        pendingAttacks.append(
            PendingAttack(
                impactTime: session.simulationTime + defense.type.impactDelay,
                defenseID: defense.id,
                pigeonID: targetID,
                pressure: defense.type.pressure
            )
        )
        events.append(
            .falconLaunched(
                defenseID: defense.id,
                pigeonID: targetID,
                impactDelay: defense.type.impactDelay
            )
        )
    }

    mutating func recordDefenseFire(at defenseIndex: Int, targetIDs: [Int]) {
        session.defenses[defenseIndex].targetPigeonIDs = targetIDs
        session.defenses[defenseIndex].cooldownRemaining = session.defenses[defenseIndex].type.cooldown
        events.append(
            .defenseFired(
                id: session.defenses[defenseIndex].id,
                type: session.defenses[defenseIndex].type,
                targetIDs: targetIDs
            )
        )
    }

    func targets(inRangeOf defense: Defense) -> [Pigeon] {
        session.pigeons
            .filter {
                $0.isTargetable
                    && $0.position.distance(to: defense.position) <= defense.type.range + 1e-12
            }
            .sorted { $0.id < $1.id }
    }

    func nearestTargetID(for defense: Defense) -> Int? {
        targets(inRangeOf: defense).min { lhs, rhs in
            let lhsDistance = lhs.position.distance(to: defense.position)
            let rhsDistance = rhs.position.distance(to: defense.position)
            if abs(lhsDistance - rhsDistance) <= 1e-12 { return lhs.id < rhs.id }
            return lhsDistance < rhsDistance
        }?.id
    }

    mutating func applySlow(toPigeonID pigeonID: Int) {
        guard let index = session.pigeons.firstIndex(where: { $0.id == pigeonID }),
              session.pigeons[index].isTargetable else {
            return
        }
        let duration = session.configuration.sprinklerSlowDuration
        session.pigeons[index].slowedUntil = max(
            session.pigeons[index].slowedUntil,
            session.simulationTime + duration
        )
        events.append(
            .slowApplied(
                pigeonID: pigeonID,
                fraction: DefenseType.sprinkler.slowFraction,
                duration: duration
            )
        )
    }

    mutating func applyPressure(
        _ amount: Double,
        toPigeonID pigeonID: Int,
        fromDefenseID defenseID: Int
    ) {
        guard let index = session.pigeons.firstIndex(where: { $0.id == pigeonID }),
              session.pigeons[index].isTargetable else {
            return
        }

        var pigeon = session.pigeons[index]
        pigeon.currentTolerance = max(0, pigeon.currentTolerance - amount)
        events.append(
            .pressureApplied(
                pigeonID: pigeon.id,
                amount: amount,
                remainingTolerance: pigeon.currentTolerance,
                defenseID: defenseID
            )
        )

        if pigeon.currentTolerance <= 0 {
            transitionPigeon(&pigeon, to: .fleeing)
            session.money += pigeon.reward
            fledThisStep += 1
            events.append(
                .pigeonFled(id: pigeon.id, reward: pigeon.reward, position: pigeon.position)
            )
            events.append(
                .moneyChanged(delta: pigeon.reward, total: session.money, reason: .pigeonReward)
            )
        } else {
            let nextState: PigeonState
            if pigeon.toleranceFraction < 0.3 {
                nextState = .panicking
            } else if pigeon.toleranceFraction <= 0.7 {
                nextState = .alert
            } else {
                nextState = .moving
            }
            transitionPigeon(&pigeon, to: nextState)
        }

        session.pigeons[index] = pigeon
    }

    mutating func transitionPigeon(_ pigeon: inout Pigeon, to newState: PigeonState) {
        guard pigeon.state != newState else { return }
        let oldState = pigeon.state
        pigeon.state = newState
        pigeon.stateElapsedTime = 0
        events.append(.pigeonStateChanged(id: pigeon.id, from: oldState, to: newState))
    }

    mutating func handleArrival(of pigeon: Pigeon) {
        let actualLoss = min(session.cleanliness, session.configuration.cleanlinessLossPerArrival)
        session.cleanliness -= actualLoss
        events.append(.pigeonReachedTarget(id: pigeon.id, cleanlinessLoss: actualLoss))
        events.append(.cleanlinessChanged(delta: -actualLoss, total: session.cleanliness))

        if session.cleanliness <= 0 {
            scheduledSpawns.removeAll(keepingCapacity: true)
            pendingAttacks.removeAll(keepingCapacity: true)
            transitionPhase(to: .defeat)
            events.append(.defeat)
        }
    }

    mutating func completeWaveIfPossible() {
        guard scheduledSpawns.isEmpty,
              pendingAttacks.isEmpty,
              session.pigeons.isEmpty,
              let completedWave = session.currentWaveNumber else {
            return
        }

        events.append(.waveCompleted(number: completedWave))
        if session.nextWave == nil {
            transitionPhase(to: .victory)
            events.append(.victory)
        } else {
            transitionPhase(to: .waveComplete)
        }
    }

    mutating func transitionPhase(to newPhase: GamePhase) {
        guard session.phase != newPhase else { return }
        let oldPhase = session.phase
        session.phase = newPhase
        events.append(.phaseChanged(from: oldPhase, to: newPhase))
    }
}
