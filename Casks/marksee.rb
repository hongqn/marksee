cask "marksee" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/hongqn/marksee/releases/download/v#{version}/MarkSee-#{version}.dmg"
  name "MarkSee"
  desc "Lightweight macOS Markdown viewer"
  homepage "https://github.com/hongqn/marksee"

  app "MarkSee.app"
end
