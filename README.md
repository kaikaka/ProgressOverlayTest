# ProgressOverlay

<h2>ProgressOverlay</h2>

<p><a href="https://travis-ci.org/matej/MBProgressHUD"><img src="https://camo.githubusercontent.com/96119ef24c508d48a83ed66fca43204f530026cb/68747470733a2f2f7472617669732d63692e6f72672f6d6174656a2f4d4250726f67726573734855442e7376673f6272616e63683d6d6173746572" alt="Build Status" data-canonical-src="https://travis-ci.org/matej/MBProgressHUD.svg?branch=master" style="max-width:100%;"></a> <a href="https://codecov.io/github/matej/MBProgressHUD?branch=master"><img src="https://camo.githubusercontent.com/87ed83229cd374f3455e93e1152ca5557e626660/68747470733a2f2f636f6465636f762e696f2f6769746875622f6d6174656a2f4d4250726f67726573734855442f636f7665726167652e7376673f6272616e63683d6d6173746572" alt="codecov.io" data-canonical-src="https://codecov.io/github/matej/MBProgressHUD/coverage.svg?branch=master" style="max-width:100%;"></a>
 <a href="https://github.com/Carthage/Carthage#adding-frameworks-to-an-application"><img src="https://camo.githubusercontent.com/3dc8a44a2c3f7ccd5418008d1295aae48466c141/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f43617274686167652d636f6d70617469626c652d3442433531442e7376673f7374796c653d666c6174" alt="Carthage compatible" data-canonical-src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" style="max-width:100%;"></a> <a href="https://cocoapods.org/pods/MBProgressHUD"><img src="https://camo.githubusercontent.com/9c6d6a7c3ded8748d2d3696c93fcfa514b973a6b/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f762f4d4250726f67726573734855442e7376673f7374796c653d666c6174" alt="CocoaPods compatible" data-canonical-src="https://img.shields.io/cocoapods/v/MBProgressHUD.svg?style=flat" style="max-width:100%;"></a> <a href="http://opensource.org/licenses/MIT"><img src="https://camo.githubusercontent.com/29a2cc0b8b0b7a3d4e2b5455d8f2502fe301426b/68747470733a2f2f696d672e736869656c64732e696f2f636f636f61706f64732f6c2f4d4250726f67726573734855442e7376673f7374796c653d666c6174" alt="License: MIT" data-canonical-src="https://img.shields.io/cocoapods/l/MBProgressHUD.svg?style=flat" style="max-width:100%;"></a></p>

<code> ProgressOverlay </code> is an iOS drop-in class that displays a translucent Overlay with an indicator and/or labels while work is being done in a background thread. This is rewritten swift for <code> MBProgressHUD </code>

This is for Objective-C <a href="https://github.com/jdg/MBProgressHUD"> MBProgressHUD </a>

<p></p>
<p>
<a href="https://thumbnail0.baidupcs.com/thumbnail/be85e18e85676f20643cb36c840beb44?fid=2718680147-250528-969036162942976&time=1476255600&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-k3TiGGCtMQAJGhfhaHF7MmrCrXI%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=6624663622952676609&dp-callid=0&size=c256_u256&quality=90">
<img src="" alt="loading" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/57a1579d6bdecc8f5f24b38decc13f72?fid=2718680147-250528-820183511600858&time=1476255600&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-jPuRRxCdwTyl5pEF2UmCzZpiFv0%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=6624869491710936406&dp-callid=0&size=c1280_u800&quality=90" style="max-width:100%;"></a>
<a href="https://thumbnail0.baidupcs.com/thumbnail/57a1579d6bdecc8f5f24b38decc13f72?fid=2718680147-250528-820183511600858&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-LGvmOdtrJVU0Raj02uBvuPlBMG8%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100">
<img src="https://thumbnail0.baidupcs.com/thumbnail/be85e18e85676f20643cb36c840beb44?fid=2718680147-250528-969036162942976&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-P%2FNh14s0vmuRX2%2Bcy09W8QgB2rc%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934980242262773256&dp-callid=0&size=c10000_u10000&quality=100" alt="simple" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/57a1579d6bdecc8f5f24b38decc13f72?fid=2718680147-250528-820183511600858&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-LGvmOdtrJVU0Raj02uBvuPlBMG8%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100" style="max-width:100%;"></a>
<a href="https://thumbnail0.baidupcs.com/thumbnail/1cb23ae90f0005231cb88849fc790365?fid=2718680147-250528-936212323624359&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-2cvjayYXCddOt6j1q0OoI1amFk0%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100">
<img src="https://thumbnail0.baidupcs.com/thumbnail/03ceb68d2a7a8ea577a07e09aff4535c?fid=2718680147-250528-85359207525099&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-o5WB79uV3N%2FUWbL5Me1%2FMoHrqsM%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934980242262773256&dp-callid=0&size=c10000_u10000&quality=100" alt="custom" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/1cb23ae90f0005231cb88849fc790365?fid=2718680147-250528-936212323624359&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-2cvjayYXCddOt6j1q0OoI1amFk0%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100" style="max-width:100%;"></a>
<a href="https://thumbnail0.baidupcs.com/thumbnail/29daf9f4d770a3b9bc377caa34f1f2ab?fid=2718680147-250528-732252968904305&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-WHAnr6aM%2FvuFBLU029d92NqRHjY%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100">
<img src="https://thumbnail0.baidupcs.com/thumbnail/8623ba503c046961abc41445a385adf3?fid=2718680147-250528-27529445525342&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-g%2B0qfDoihLvSpOpzHN5QaLReHo4%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934980242262773256&dp-callid=0&size=c10000_u10000&quality=100" alt="detail" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/29daf9f4d770a3b9bc377caa34f1f2ab?fid=2718680147-250528-732252968904305&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-WHAnr6aM%2FvuFBLU029d92NqRHjY%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100" style="max-width:100%;"></a>
<a href="https://thumbnail0.baidupcs.com/thumbnail/1ff14ec3070990d607451cb19b720d28?fid=2718680147-250528-739593846914753&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-x2XDNzE37DYiRK6uuS1ZPUwBGP8%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100">
<img src="https://thumbnail0.baidupcs.com/thumbnail/25c5ea988483b2fb8bc2d1d561df2c99?fid=2718680147-250528-983438359466802&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-mBOfhfkZB%2BBO8HZr2Y2GVuyjs%2B8%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934980242262773256&dp-callid=0&size=c10000_u10000&quality=100" alt="detail" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/1ff14ec3070990d607451cb19b720d28?fid=2718680147-250528-739593846914753&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-x2XDNzE37DYiRK6uuS1ZPUwBGP8%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100" style="max-width:100%;"></a>
<a href="https://thumbnail0.baidupcs.com/thumbnail/08ff47b764ed3ff88ad030e021d5bd03?fid=2718680147-250528-1069927098675392&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-sfBHseGvzPfoQlSgWJTQZGb%2BdtM%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100">
<img src="https://thumbnail0.baidupcs.com/thumbnail/bfc182176e2dbecb76d30490bc69c67c?fid=2718680147-250528-761696783300768&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-wpCs%2BUVrpbdeWLWNZ9l59oD1ny0%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934980242262773256&dp-callid=0&size=c10000_u10000&quality=100" alt="button" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/08ff47b764ed3ff88ad030e021d5bd03?fid=2718680147-250528-1069927098675392&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-sfBHseGvzPfoQlSgWJTQZGb%2BdtM%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100" style="max-width:100%;"></a>
<a href="https://thumbnail0.baidupcs.com/thumbnail/69fb6b09c212d1cc73d6da1abf57578a?fid=2718680147-250528-720305681032857&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-TSr4KIY06qu3KaUmkOd2at6egK0%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100">
<img src="https://thumbnail0.baidupcs.com/thumbnail/4861bb546085d37f271ce8c2aadeb401?fid=2718680147-250528-24022983731777&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-060BRj6t4xVHse8hFwYNsrB0D4w%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934980242262773256&dp-callid=0&size=c10000_u10000&quality=100" alt="bar" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/69fb6b09c212d1cc73d6da1abf57578a?fid=2718680147-250528-720305681032857&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-TSr4KIY06qu3KaUmkOd2at6egK0%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934840138362816018&dp-callid=0&size=c850_u580&quality=100" style="max-width:100%;"></a>
<a href="https://thumbnail0.baidupcs.com/thumbnail/1e9a41d4e90407a927befbadf4bf6dd8?fid=2718680147-250528-80949732335003&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-gIcVPfg8u6rCk4zZ6leWzY7NG0g%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934659058474715089&dp-callid=0&size=c850_u580&quality=100">
<img src="https://thumbnail0.baidupcs.com/thumbnail/02a167e3dd754c4637c97b4ca4f6bbf4?fid=2718680147-250528-239870768002215&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-LM4DOolgbD6wxnCgVpCFTOtOa%2Bc%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934980242262773256&dp-callid=0&size=c10000_u10000&quality=100" alt="message here" data-canonical-src="https://thumbnail0.baidupcs.com/thumbnail/1e9a41d4e90407a927befbadf4bf6dd8?fid=2718680147-250528-80949732335003&time=1473685200&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-gIcVPfg8u6rCk4zZ6leWzY7NG0g%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=5934659058474715089&dp-callid=0&size=c850_u580&quality=100" style="max-width:100%;"></a>
</p>


<h2>Requirements</h2>

ProgressOverlay works on iOS 9+ and requires ARC to build

You will need the latest developer tools in order to build ProgressOverlay. Old Xcode versions might work, but compatibility will not be explicitly maintained.

#<h2>Adding ProgressOverlay to your project <h2>

#<h3>CocoaPods</h3>

<h2> License </h2>

<p>This code is distributed under the terms and conditions of the <a href="/sugarAndsugar/ProgressOverlay
/master/row/LICENSE">MIT license</a>.</p>
