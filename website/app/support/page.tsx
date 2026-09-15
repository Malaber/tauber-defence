import type { Metadata } from 'next';
import { Bug, ExternalLink, Mail, MessageCircleQuestion } from 'lucide-react';
import { SiteFooter, SiteHeader } from '@/components/site-shell';

export const dynamic = 'force-static';

export const metadata: Metadata = {
  title: 'Support',
  description: 'Hilfe und Kontakt für Tauber Defence auf iPhone und iPad.',
  alternates: { canonical: '/support/' },
};

export default function SupportPage() {
  return (
    <div className="site-shell">
      <SiteHeader />
      <main id="main" className="content-main page-width">
        <header className="content-hero">
          <p className="eyebrow">Bürgertelefon</p>
          <h1>Support ohne Warteschleifenmusik.</h1>
          <p>Probleme mit Tauben, Türmen oder Rüdigers Haltung? Wir helfen.</p>
        </header>
        <section className="contact-grid" aria-label="Kontaktmöglichkeiten">
          <article>
            <Mail aria-hidden="true" />
            <h2>E-Mail</h2>
            <p>Für Fragen, Feedback und Probleme mit dem Spiel.</p>
            <a className="contact-action" href="mailto:support-tauber-defence@schaedler.rocks?subject=Tauber%20Defence%20Support">support-tauber-defence@schaedler.rocks</a>
          </article>
          <article>
            <Bug aria-hidden="true" />
            <h2>Fehler melden</h2>
            <p>Technische Details und reproduzierbare Schritte passen gut in ein GitHub-Issue.</p>
            <a className="contact-action" href="https://github.com/Malaber/tauber-defence/issues/new">Issue öffnen <ExternalLink aria-hidden="true" /></a>
          </article>
        </section>
        <section className="support-details prose-section">
          <MessageCircleQuestion aria-hidden="true" />
          <div>
            <h2>Hilfreiche Angaben</h2>
            <p>Bitte nenne Gerätemodell, iOS-Version, App-Version und was unmittelbar vor dem Problem passiert ist. Keine persönlichen oder vertraulichen Daten mitsenden.</p>
            <p>Antworten erfolgen so bald wie möglich. Tauber Defence bietet derzeit keine In-App-Käufe, Konten oder Online-Spielstände.</p>
          </div>
        </section>
      </main>
      <SiteFooter />
    </div>
  );
}
