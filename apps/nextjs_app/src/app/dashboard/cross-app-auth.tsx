"use client";

import { useAuth } from "@clerk/nextjs";
import { useState } from "react";

export function CrossAppAuth() {
  const { getToken } = useAuth();
  const [result, setResult] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const testCrossAppAuth = async () => {
    setLoading(true);
    setResult(null);
    try {
      const token = await getToken();
      const phoenixUrl =
        process.env.NEXT_PUBLIC_PHOENIX_API_URL || "http://localhost:4000";
      const res = await fetch(`${phoenixUrl}/api/verify`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await res.json();
      setResult(JSON.stringify(data, null, 2));
    } catch (err) {
      setResult(
        `Error: ${err instanceof Error ? err.message : "Unknown error"}`
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white border rounded-lg p-6">
      <h3 className="text-lg font-semibold mb-4">Cross-App Auth Test</h3>
      <p className="text-gray-600 text-sm mb-4">
        Sends your Clerk JWT to the Phoenix app&apos;s /api/verify endpoint.
      </p>
      <button
        onClick={testCrossAppAuth}
        disabled={loading}
        className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
      >
        {loading ? "Testing..." : "Test Cross-App Auth"}
      </button>
      {result && (
        <pre className="mt-4 p-4 bg-gray-100 rounded text-sm overflow-auto">
          {result}
        </pre>
      )}
    </div>
  );
}
