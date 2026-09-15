import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL('https://tauber-defence.malaber.de'),
  title: {
    default: 'Tauber Defence – Die Stadt hat genug gegurrt',
    template: '%s · Tauber Defence',
  },
  description:
    'Humoristisches 2.5D-Tower-Defense-Spiel für iPhone und iPad. Tauben verlieren ihre Nerven, nicht ihr Leben.',
  alternates: { canonical: '/' },
  openGraph: {
    type: 'website',
    locale: 'de_DE',
    siteName: 'Tauber Defence',
    title: 'Tauber Defence – Die Stadt hat genug gegurrt',
    description: 'Tower Defense mit Pressure, Nerven und sehr dramatischen Stadttauben.',
    images: [{ url: '/og.png', width: 1200, height: 630, alt: 'Tauber Defence' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Tauber Defence – Die Stadt hat genug gegurrt',
    description: 'Tower Defense mit Pressure, Nerven und sehr dramatischen Stadttauben.',
    images: ['/og.png'],
  },
  icons: { icon: '/favicon.svg', apple: '/app-icon.png' },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="de">
      <body>{children}</body>
    </html>
  );
}
