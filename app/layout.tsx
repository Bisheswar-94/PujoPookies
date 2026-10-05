import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = { title: 'Pujo Pookie · Find your people this Pujo', description: 'A little adda. A little adventure. Find your Pujo companion, matched by plan, vibe and availability.' };
export default function RootLayout({children}: Readonly<{children:React.ReactNode}>) { return <html lang="en"><body>{children}</body></html>; }
