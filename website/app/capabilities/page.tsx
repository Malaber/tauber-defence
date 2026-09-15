import type { Metadata } from 'next';
import { Boxes, Gamepad2, HeartHandshake, MapPinned, Shield, Waves } from 'lucide-react';
import { SiteFooter, SiteHeader } from '@/components/site-shell';

export const dynamic = 'force-static';

export const metadata: Metadata = {
  title: 'Das Spiel',
  description: 'Spielprinzip und Funktionen von Tauber Defence.',
  alternates: { canonical: '/capabilities/' },
};

const items = [
  [MapPinned, 'Ein Marktplatz', 'Eine handgebaute Route führt vom Stadtrand direkt zum gefährdeten Café.'],
  [Waves, 'Fünf Wellen', 'Von fünf Stadttauben bis zu Rüdiger mit 1.000 Punkten Toleranz.'],
  [Shield, 'Drei Abwehrtypen', 'Single Target, Flächeneffekt, Slow und verzögerter Falkeneinsatz.'],
  [Boxes, '2D trifft 3D', 'Flache Original-Tauben mit Schatten in einer stilisierten Low-Poly-Diorama-Stadt.'],
  [Gamepad2, 'Native Steuerung', 'Für Touch, Querformat, iPhone und iPad mit SwiftUI und RealityKit gebaut.'],
  [HeartHandshake, 'Taubenfreundlich', 'Pressure senkt Nerven. Bei null fliegen Tauben davon – sie werden nie verletzt.'],
] as const;

export default function CapabilitiesPage() {
  return (
    <div className="site-shell">
      <SiteHeader />
      <main id="main" className="content-main page-width">
        <header className="content-hero">
          <p className="eyebrow">Einsatzhandbuch</p>
          <h1>Klassisches Tower Defense. Unklassische Tauben.</h1>
          <p>Ein kleiner, kompletter Vertical Slice ohne Konten, Onlinezwang oder spielerische Nebelkerzen.</p>
        </header>
        <section className="capability-list" aria-label="Spielumfang">
          {items.map(([CapabilityIcon, title, copy]) => (
            <article key={title}>
              <CapabilityIcon aria-hidden="true" />
              <h2>{title}</h2>
              <p>{copy}</p>
            </article>
          ))}
        </section>
        <section className="spec-strip">
          <span>iOS 18+</span><span>Landscape</span><span>Offline</span><span>Keine IAP</span><span>Kein Tracking</span>
        </section>
      </main>
      <SiteFooter />
    </div>
  );
}
