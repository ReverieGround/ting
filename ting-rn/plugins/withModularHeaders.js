const { withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

/**
 * Adds `use_modular_headers!` to the iOS Podfile.
 * Required for Firebase Swift pods that depend on non-modular targets.
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

      if (!podfile.includes('use_modular_headers!')) {
        podfile = podfile.replace(
          /platform :ios,/,
          'use_modular_headers!\nplatform :ios,',
        );
        fs.writeFileSync(podfilePath, podfile);
      }

      return config;
    },
  ]);
};
