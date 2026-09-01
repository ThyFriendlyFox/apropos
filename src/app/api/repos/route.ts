import { NextRequest, NextResponse } from "next/server";
import { SAMPLE_REPOS } from "@/data/sampleRepos";
import { fetchUserRepos } from "@/lib/githubService";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const username = searchParams.get("username");
  const token = searchParams.get("token") || undefined;
  const filterIosOnly = searchParams.get("iosOnly") === "true";

  let repos = SAMPLE_REPOS;

  if (username && username.trim() !== "" && username !== "demo") {
    try {
      const liveRepos = await fetchUserRepos(username, token);
      if (liveRepos.length > 0) {
        // Merge or replace
        repos = liveRepos;
      }
    } catch (e) {
      console.warn("Using sample repos due to fetch failure", e);
    }
  }

  const result = filterIosOnly ? repos.filter(r => r.hasIosBuild) : repos;

  return NextResponse.json({
    success: true,
    repos: result,
    totalCount: repos.length,
    iosCount: repos.filter(r => r.hasIosBuild).length
  });
}
