import { Bird, ExternalLink } from 'lucide-react';
import Link from 'next/link';

export function SiteHeader() {
  return (
    <header className="site-header">
      <a className="skip-link" href="#main">Zum Inhalt springen</a>
      <div className="page-width header-inner">
        <Link className="brand" href="/" aria-label="Tauber Defence Startseite">
          <span className="brand-mark"><Bird aria-hidden="true" /></span>
          <span>TAUBER <strong>DEFENCE</strong></span>
        </Link>
        <nav aria-label="Hauptnavigation">
          <Link href="/capabilities/">Das Spiel</Link>
          <Link href="/support/">Support</Link>
          <Link href="/privacy/">Datenschutz</Link>
        </nav>
      </div>
    </header>
  );
}

export function SiteFooter() {
  return (
    <footer className="site-footer">
      <div className="page-width footer-inner">
        <div>
          <Link className="brand footer-brand" href="/">
            <span className="brand-mark"><Bird aria-hidden="true" /></span>
            <span>TAUBER <strong>DEFENCE</strong></span>
          </Link>
          <p>Nerven bewahren seit 2026.</p>
        </div>
        <nav aria-label="Fußnavigation">
          <Link href="/support/">Support</Link>
          <Link href="/privacy/">Datenschutz</Link>
          <a href="https://github.com/Malaber/tauber-defence"><ExternalLink aria-hidden="true" /> GitHub</a>
        </nav>
      </div>
    </footer>
  );
}
