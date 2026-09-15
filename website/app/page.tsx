import {
  Bird,
  Coins,
  Droplets,
  Eye,
  ShieldCheck,
  Sparkles,
  Wind,
} from 'lucide-react';
import Image from 'next/image';
import Link from 'next/link';
import { SiteFooter, SiteHeader } from '@/components/site-shell';

export const dynamic = 'force-static';

const defenses = [
  {
    icon: Eye,
    name: 'Plastik-Uhu',
    price: '100 €',
    copy: 'Starrt einzelne Tauben mit maximaler amtlicher Missbilligung an.',
    tone: 'ochre',
  },
  {
    icon: Droplets,
    name: 'Rasensprenger',
    price: '150 €',
    copy: 'Duscht ganze Gruppen, senkt Nerven und bremst den Anmarsch.',
    tone: 'blue',
  },
  {
    icon: Bird,
    name: 'Falkner',
    price: '300 €',
    copy: 'Große Reichweite. Großer Auftritt. Sehr kurze Diskussion.',
    tone: 'coral',
  },
];

export default function Home() {
  return (
    <div className="site-shell">
      <SiteHeader />
      <main id="main">
        <section className="hero page-width">
          <div className="hero-copy">
            <p className="eyebrow"><Sparkles aria-hidden="true" /> Mobile Taubenabwehrbehörde</p>
            <h1>Die Stadt hat genug gegurrt.</h1>
            <p className="hero-lede">
              Baue absurde Abwehranlagen, bring Tauben aus der Fassung und halte
              das Café sauber. Tower Defense mit Nerven statt Trefferpunkten.
            </p>
            <div className="hero-actions">
              <span className="store-badge" aria-label="Geplant für iPhone und iPad">
                <span>GEPLANT FÜR</span>
                <strong>iPhone + iPad</strong>
              </span>
              <a className="text-link" href="#einsatz">Einsatzbericht lesen <span aria-hidden="true">↓</span></a>
            </div>
            <p className="kind-note"><ShieldCheck aria-hidden="true" /> Keine Taube wird verletzt. Nur dramatisch verscheucht.</p>
          </div>
          <div className="hero-art" aria-label="Taube mit Nudelsiebhelm, Megafon und Deckelschild">
            <div className="icon-frame">
              <Image
                src="/app-icon.png"
                alt="Paniktaube verteidigt sich mit Nudelsiebhelm und Topfdeckel"
                width={1024}
                height={1024}
                priority
                unoptimized
              />
            </div>
            <div className="stamp" aria-hidden="true">GURR<br />ALARM</div>
          </div>
        </section>

        <section className="ticker" aria-label="Spielmeldungen">
          <div>
            <span>GURR COMBO ×5</span>
            <span>STADTTAUBE ENTFERNT</span>
            <span>ORDNUNGSAMT INTENSIFIES</span>
            <span>+ 50 €</span>
          </div>
        </section>

        <section className="loop-section page-width" id="einsatz">
          <div className="section-heading">
            <p className="eyebrow">Einsatzablauf</p>
            <h2>Nerven verlieren ausdrücklich erwünscht.</h2>
          </div>
          <ol className="game-loop">
            <li>
              <span className="step-number">01</span>
              <Coins aria-hidden="true" />
              <h3>Stadtbudget verteilen</h3>
              <p>Acht feste Bauplätze. Drei fragwürdige Lösungen. Harte Entscheidungen.</p>
            </li>
            <li>
              <span className="step-number">02</span>
              <Bird aria-hidden="true" />
              <h3>Tauben beobachten</h3>
              <p>Flache 2D-Stadttauben marschieren durch eine kleine 3D-Diorama-Stadt.</p>
            </li>
            <li>
              <span className="step-number">03</span>
              <Wind aria-hidden="true" />
              <h3>Pressure erzeugen</h3>
              <p>Sinkt die Toleranz auf null, folgt Panik, Abflug und eine wohlverdiente Prämie.</p>
            </li>
          </ol>
        </section>

        <section className="defense-section">
          <div className="page-width">
            <div className="section-heading split-heading">
              <div>
                <p className="eyebrow">Werkzeugkasten</p>
                <h2>Drei Wege, „bitte weiterfliegen“ zu sagen.</h2>
              </div>
              <p>Automatisches Targeting, eigene Reichweiten und unverhältnismäßig viel Feedback.</p>
            </div>
            <div className="defense-grid">
              {defenses.map(({ icon: Icon, name, price, copy, tone }) => (
                <article className={`defense-item ${tone}`} key={name}>
                  <div className="defense-icon"><Icon aria-hidden="true" /></div>
                  <p className="defense-price">{price}</p>
                  <h3>{name}</h3>
                  <p>{copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="boss-section page-width">
          <div className="boss-art">
            <Image
              src="/pigeon-rudiger.png"
              alt="Rüdiger, eine besonders große und unbeeindruckte Stadttaube"
              width={512}
              height={512}
              unoptimized
            />
          </div>
          <div className="boss-copy">
            <p className="eyebrow coral-text">Welle 5</p>
            <h2>Nicht so tief, Rüdiger!</h2>
            <p>
              Vier Wellen waren nur Papierkram. Dann erscheint Rüdiger: 1.000
              Nervenpunkte, ein Blick wie Granit und keinerlei Respekt vor deinem Uhu.
            </p>
            <dl className="boss-stats">
              <div><dt>Toleranz</dt><dd>1.000</dd></div>
              <div><dt>Tempo</dt><dd>0,7</dd></div>
              <div><dt>Prämie</dt><dd>500 €</dd></div>
            </dl>
          </div>
        </section>

        <section className="promise-section page-width">
          <div>
            <p className="eyebrow">Amtlich angenehm</p>
            <h2>Spielspaß ohne Datengurren.</h2>
          </div>
          <div className="promise-copy">
            <p>Kein Konto. Keine Werbung. Kein Tracking. Keine Analytics. Kein Backend.</p>
            <Link className="text-link" href="/privacy/">Datenschutz im Detail <span aria-hidden="true">→</span></Link>
          </div>
        </section>

        <section className="final-cta">
          <div className="page-width">
            <Image
              src="/pigeon-normal.png"
              alt="Eine skeptisch blickende Stadttaube"
              width={512}
              height={512}
              unoptimized
            />
            <div>
              <p className="eyebrow">Demnächst</p>
              <h2>Marktplatz retten. Rüdiger enttäuschen.</h2>
              <p>Native für iPhone und iPad. Entwickelt mit SwiftUI und RealityKit.</p>
            </div>
          </div>
        </section>
      </main>
      <SiteFooter />
    </div>
  );
}
