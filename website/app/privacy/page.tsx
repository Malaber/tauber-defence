import type { Metadata } from 'next';
import { ShieldCheck } from 'lucide-react';
import Link from 'next/link';
import { SiteFooter, SiteHeader } from '@/components/site-shell';

export const dynamic = 'force-static';

export const metadata: Metadata = {
  title: 'Datenschutz',
  description: 'Datenschutzerklärung für Tauber Defence.',
  alternates: { canonical: '/privacy/' },
};

export default function PrivacyPage() {
  return (
    <div className="site-shell">
      <SiteHeader />
      <main id="main" className="content-main page-width">
        <header className="content-hero privacy-hero">
          <ShieldCheck aria-hidden="true" />
          <p className="eyebrow">Datenschutz</p>
          <h1>Dein Spiel bleibt auf deinem Gerät.</h1>
          <p>Gültig ab 15. September 2026</p>
        </header>
        <article className="legal-copy">
          <section>
            <h2>Kurzfassung</h2>
            <p>Tauber Defence hat keine Benutzerkonten, Werbung, Analytics, Tracking oder Serverdienste. Die App erhebt, überträgt oder verkauft keine personenbezogenen Daten.</p>
          </section>
          <section>
            <h2>Spieldaten</h2>
            <p>Der aktuelle Spielzustand – etwa Budget, Sauberkeit, Wellen und platzierte Abwehr – wird für die laufende Partie im Arbeitsspeicher verarbeitet. Der aktuelle Build speichert diese Daten nicht dauerhaft und überträgt sie nicht.</p>
          </section>
          <section>
            <h2>Netzwerk und Drittanbieter</h2>
            <p>Das Spiel selbst benötigt keine Netzwerkverbindung und bindet keine Werbe-, Analyse- oder Tracking-SDKs ein. Support- und Datenschutzlinks öffnen nur nach deiner Auswahl eine externe Webseite oder E-Mail-App; deren Anbieter verarbeiten Daten nach ihren eigenen Richtlinien.</p>
          </section>
          <section>
            <h2>Kinder und Käufe</h2>
            <p>Tauber Defence erhebt wissentlich keine Daten von Kindern. Die App enthält im aktuellen Build keine In-App-Käufe, Abonnements oder personalisierte Werbung.</p>
          </section>
          <section>
            <h2>Änderungen</h2>
            <p>Falls eine spätere Version Online-Dienste oder Datenerhebung ergänzt, werden diese Erklärung und Apples Datenschutzangaben vor Veröffentlichung aktualisiert.</p>
          </section>
          <section>
            <h2>Kontakt</h2>
            <p>Datenschutzfragen bitte an <a href="mailto:privacy-tauber-defence@schaedler.rocks">privacy-tauber-defence@schaedler.rocks</a> oder über die <Link href="/support/">Supportseite</Link>.</p>
          </section>
        </article>
      </main>
      <SiteFooter />
    </div>
  );
}
