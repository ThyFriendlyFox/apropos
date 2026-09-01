import { RepoApp, IOSBuildType } from "@/types/repo";

export async function detectIosBuildFromRepoTree(files: string[]): Promise<{ hasIosBuild: boolean; buildType: IOSBuildType; tags: string[] }> {
  const fileSet = new Set(files.map(f => f.toLowerCase()));
  
  // Check for Xcode project / workspace / Swift files
  const hasXcodeProj = files.some(f => f.includes(".xcodeproj") || f.includes(".xcworkspace") || f.endsWith(".swift") || f.includes("/ios/"));
  const hasPodfile = files.some(f => f.toLowerCase().endsWith("podfile"));
  const hasAppJson = files.some(f => f.endsWith("app.json"));
  const hasPackageJson = files.some(f => f.endsWith("package.json"));
  const hasPubspec = files.some(f => f.endsWith("pubspec.yaml"));
  const hasCapacitor = files.some(f => f.includes("capacitor.config"));

  if (hasAppJson && files.some(f => f.includes("expo"))) {
    return {
      hasIosBuild: true,
      buildType: "expo",
      tags: ["Expo", "React Native", "iOS Build Target"]
    };
  }

  if (hasPubspec && hasXcodeProj) {
    return {
      hasIosBuild: true,
      buildType: "flutter",
      tags: ["Flutter", "iOS Runner", "Xcode"]
    };
  }

  if (hasCapacitor) {
    return {
      hasIosBuild: true,
      buildType: "capacitor-ionic",
      tags: ["Capacitor", "iOS WKWebView"]
    };
  }

  if (hasXcodeProj || hasPodfile) {
    if (hasPackageJson) {
      return {
        hasIosBuild: true,
        buildType: "react-native",
        tags: ["React Native", "iOS Native Workspace"]
      };
    }
    return {
      hasIosBuild: true,
      buildType: "swift-xcode",
      tags: ["Swift / Xcode", "Native iOS"]
    };
  }

  return {
    hasIosBuild: false,
    buildType: "pwa-web",
    tags: ["No iOS Build Target"]
  };
}

export async function fetchUserRepos(username: string, token?: string): Promise<RepoApp[]> {
  try {
    const headers: Record<string, string> = {
      "Accept": "application/vnd.github.v3+json",
      "User-Agent": "iOS-Repo-Runner-App",
    };
    if (token) {
      headers["Authorization"] = `token ${token}`;
    }

    const res = await fetch(`https://api.github.com/users/${username}/repos?sort=updated&per_page=100`, {
      headers,
      next: { revalidate: 60 }
    });

    if (!res.ok) {
      throw new Error(`GitHub API error: ${res.statusText}`);
    }

    const githubRepos: Array<{
      id: number;
      name: string;
      owner: { login: string; avatar_url: string };
      description: string | null;
      stargazers_count: number;
      forks_count: number;
      language: string | null;
      updated_at: string;
      default_branch: string;
      html_url: string;
    }> = await res.json();

    // Check each repo for iOS build artifacts / indicators
    const reposWithIosStatus: RepoApp[] = await Promise.all(
      githubRepos.map(async (r) => {
        // Quick heuristics on name / description / languages
        const text = `${r.name} ${r.description || ""} ${r.language || ""}`.toLowerCase();
        const isLikelyIos = text.includes("ios") || text.includes("swift") || text.includes("react-native") || text.includes("expo") || text.includes("flutter") || text.includes("xcode");
        
        let buildType: IOSBuildType = "swift-xcode";
        if (text.includes("expo")) buildType = "expo";
        else if (text.includes("flutter")) buildType = "flutter";
        else if (text.includes("react-native") || text.includes("native")) buildType = "react-native";
        else if (text.includes("capacitor") || text.includes("ionic")) buildType = "capacitor-ionic";

        return {
          id: `gh-${r.id}`,
          name: r.name,
          owner: r.owner.login,
          description: r.description || "No description provided",
          stars: r.stargazers_count,
          forks: r.forks_count,
          language: r.language || (isLikelyIos ? "Swift" : "JavaScript"),
          updatedAt: new Date(r.updated_at).toLocaleDateString(),
          hasIosBuild: isLikelyIos,
          buildType,
          buildDetails: {
            bundleId: `com.${r.owner.login}.${r.name.replace(/[^a-zA-Z0-9]/g, "")}`,
            scheme: r.name.toLowerCase().replace(/[^a-z0-9]/g, ""),
            version: "1.0.0",
            hasLiveDemo: true,
            appType: "built-in",
            icon: isLikelyIos ? "Smartphone" : "Code",
            themeColor: isLikelyIos ? "#3B82F6" : "#64748B",
            tags: isLikelyIos ? ["iOS Target", buildType] : ["Web / Server"],
            demoUrl: r.html_url,
            hasTestFlightOrArtifact: false
          }
        };
      })
    );

    return reposWithIosStatus;
  } catch (err) {
    console.error("Failed to fetch GitHub repos, fallback to local dataset", err);
    return [];
  }
}
