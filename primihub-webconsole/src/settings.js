import brand from '@/brand.config'
module.exports = {
  title: '隐私计算平台',

  /**
   * @type {string} html string
   * @description Whether change company introduction eg. <p style="font-size: 36px; text-align:center">...</p>
   */
  introduction: '',

  /**
   * @type {boolean} true | false
   * @description Whether fix the header
   */
  fixedHeader: true,

  /**
   * @type {boolean} true | false
   * @description Whether show the logo in sidebar
   */
  sidebarLogo: true,

  /**
   * @type {boolean} true | false
   * @description for google analytics
   */
  googleAnalytics: true,
  loginLogoUrl: '', // login page logo
  isShowLogo: true,
  isOpenTracing: false,
  logoUrl: '/images/logo-primihub.png', // navbar logo
  logoTitle: '', // navbar logo title
  showLogoTitle: false,
  favicon: '', // browser icon
  isHideFadeBack: true, // show or hide suggestions and feedback
  isHideAppMarket: true, // show or hide application market
  isHideFooterVersion: true, // show or hide footer text
  footerText: brand.footer // when show footer text
}
