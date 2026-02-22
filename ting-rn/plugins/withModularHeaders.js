const { withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

/**
 * Adds `use_modular_headers!` to the iOS Podfile for Firebase Swift pods,
 * then disables modular headers for gRPC pods (they don't support it).
 */
module.exports = function withModularHeaders(config) {
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

      // Add use_modular_headers! before platform declaration
      if (!podfile.includes('use_modular_headers!')) {
        podfile = podfile.replace(
          /platform :ios,/,
          'use_modular_headers!\nplatform :ios,',
        );
      }

      // Disable modular headers for gRPC pods (they lack proper module maps)
      if (!podfile.includes("'gRPC-Core'")) {
        podfile = podfile.replace(
          /use_expo_modules!/,
          "use_expo_modules!\n  pod 'gRPC-Core', :modular_headers => false\n  pod 'gRPC-C++', :modular_headers => false",
        );
      }

      fs.writeFileSync(podfilePath, podfile);
      return config;
    },
  ]);
};
