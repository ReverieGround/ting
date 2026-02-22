const { withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

/**
 * Selectively builds Firebase pods as static frameworks so Swift headers
 * (-Swift.h) are generated, while keeping React/RNFB/gRPC as static
 * libraries to avoid non-modular include errors.
 */
module.exports = function withFirebaseFixes(config) {
  return withDangerousMod(config, [
    'ios',
    async (config) => {
      const podfilePath = path.join(
        config.modRequest.projectRoot,
        'ios',
        'Podfile',
      );

      if (!fs.existsSync(podfilePath)) return config;

      let podfile = fs.readFileSync(podfilePath, 'utf8');

      if (!podfile.includes('# [withFirebaseFixes]')) {
        const preInstall = `
# [withFirebaseFixes] Build only Firebase pods as static frameworks
pre_install do |installer|
  firebase_prefixes = %w[Firebase Google RecaptchaInterop GTMSessionFetcher PromisesObjC nanopb FBLPromises]
  installer.pod_targets.each do |pod|
    if firebase_prefixes.any? { |prefix| pod.name.start_with?(prefix) }
      def pod.build_type
        Pod::BuildType.static_framework
      end
    end
  end
end
`;
        // Insert before the target block
        podfile = podfile.replace(
          /(target\s+['"])/,
          `${preInstall}\n$1`,
        );

        fs.writeFileSync(podfilePath, podfile);
      }

      return config;
    },
  ]);
};
