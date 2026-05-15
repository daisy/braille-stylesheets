// remove media queries that are not screen

module.exports = () => {
  return {
    postcssPlugin: 'filter-media',
    AtRule(atRule) {
      if (atRule.name === 'media') {
        const params = atRule.params.toLowerCase();
        if (!params.includes('screen')) {
          atRule.remove();
        }
      }
    }
  };
};
module.exports.postcss = true;
