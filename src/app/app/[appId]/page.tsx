import { SAMPLE_REPOS } from "@/data/sampleRepos";
import AppRunnerClient from "./AppRunnerClient";

// Every runnable app id, so this route works in a static export as well as
// on a server. The export is what Apropos runs on the phone.
export function generateStaticParams() {
  return SAMPLE_REPOS.map((repo) => ({ appId: repo.id }));
}

export default async function AppRunnerPage({
  params,
}: {
  params: Promise<{ appId: string }>;
}) {
  const { appId } = await params;
  return <AppRunnerClient appId={appId} />;
}
