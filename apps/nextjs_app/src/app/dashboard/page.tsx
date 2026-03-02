import { currentUser, auth } from "@clerk/nextjs/server";
import { CrossAppAuth } from "./cross-app-auth";

export default async function DashboardPage() {
  const user = await currentUser();
  const { orgId, orgRole } = await auth();

  return (
    <div className="max-w-2xl mx-auto mt-8">
      <h2 className="text-2xl font-bold mb-6">Dashboard</h2>

      <div className="bg-white border rounded-lg p-6 mb-6">
        <h3 className="text-lg font-semibold mb-4">User Info</h3>
        <dl className="space-y-2">
          <div className="flex gap-2">
            <dt className="font-medium text-gray-600">Clerk ID:</dt>
            <dd className="font-mono text-sm">{user?.id}</dd>
          </div>
          <div className="flex gap-2">
            <dt className="font-medium text-gray-600">Email:</dt>
            <dd>{user?.emailAddresses[0]?.emailAddress}</dd>
          </div>
          <div className="flex gap-2">
            <dt className="font-medium text-gray-600">Name:</dt>
            <dd>
              {user?.firstName} {user?.lastName}
            </dd>
          </div>
        </dl>
      </div>

      <div className="bg-white border rounded-lg p-6 mb-6">
        <h3 className="text-lg font-semibold mb-4">Organization</h3>
        <dl className="space-y-2">
          <div className="flex gap-2">
            <dt className="font-medium text-gray-600">Org ID:</dt>
            <dd className="font-mono text-sm">{orgId ?? "None"}</dd>
          </div>
          <div className="flex gap-2">
            <dt className="font-medium text-gray-600">Org Role:</dt>
            <dd>{orgRole ?? "None"}</dd>
          </div>
        </dl>
      </div>

      <CrossAppAuth />
    </div>
  );
}
