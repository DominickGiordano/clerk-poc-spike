import { SignedIn, SignedOut } from "@clerk/nextjs";
import Link from "next/link";

export default function Home() {
  return (
    <div className="max-w-2xl mx-auto mt-8">
      <h2 className="text-2xl font-bold mb-4">Clerk Auth Spike</h2>
      <SignedOut>
        <p className="text-gray-600">Sign in to access the dashboard.</p>
      </SignedOut>
      <SignedIn>
        <p className="mb-4">You are signed in.</p>
        <Link href="/dashboard" className="text-blue-600 underline">
          Go to Dashboard
        </Link>
      </SignedIn>
    </div>
  );
}
