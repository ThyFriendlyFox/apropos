export type IOSBuildType = 
  | "expo" 
  | "react-native" 
  | "swift-xcode" 
  | "flutter" 
  | "capacitor-ionic" 
  | "pwa-web";

export interface RepoApp {
  id: string;
  name: string;
  owner: string;
  description: string;
  stars: number;
  forks: number;
  language: string;
  updatedAt: string;
  hasIosBuild: boolean;
  buildType: IOSBuildType;
  buildDetails: {
    bundleId?: string;
    scheme?: string;
    expoSlug?: string;
    xcodeProjPath?: string;
    version?: string;
    hasLiveDemo: boolean;
    appType: "built-in" | "expo-snack" | "web-bundle" | "external-url";
    demoUrl?: string;
    appComponentKey?: string;
    icon: string;
    themeColor: string;
    tags: string[];
    iosTargetVersion?: string;
    hasTestFlightOrArtifact?: boolean;
    artifactUrl?: string;
    qrPayload?: string;
  };
}

export interface UserAccount {
  username: string;
  avatarUrl: string;
  name: string;
  totalRepos: number;
  iosReposCount: number;
}
