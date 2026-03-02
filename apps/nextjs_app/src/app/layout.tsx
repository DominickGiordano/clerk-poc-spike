import {
  ClerkProvider,
  SignedIn,
  SignedOut,
  SignInButton,
  UserButton,
} from "@clerk/nextjs";
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Clerk POC - Next.js",
  description: "Clerk authentication spike - Next.js app",
};

// Force dynamic rendering — ClerkProvider needs publishableKey at runtime
export const dynamic = "force-dynamic";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider dynamic>
      <html lang="en">
        <body
          className={`${geistSans.variable} ${geistMono.variable} antialiased bg-gray-900 text-green-400`}
        >
          <header className="flex justify-between items-center p-4 border-b border-gray-700">
            <h1 className="text-lg font-semibold text-green-400">Clerk POC - Next.js</h1>
            <div>
              <SignedOut>
                <SignInButton mode="modal" />
              </SignedOut>
              <SignedIn>
                <UserButton />
              </SignedIn>
            </div>
          </header>
          <main className="p-4">{children}</main>
        </body>
      </html>
    </ClerkProvider>
  );
}
