const xianyuUrl = 'https://www.goofish.com/';
const xianyuLink = { label: '去闲鱼搜索 ikesman', href: xianyuUrl, marketplace: true };

const packages = [
  { title: '2018 款 CS75 降级包', tags: ['系统包', '2018', '闲鱼获取'], path: xianyuUrl, marketplace: true, place: '购买后改名 update.zip → U 盘根目录', note: '购买时说明车型与年款；放 U 盘前必须确认文件名为 update.zip，且不解压。' },
  { title: '2019 款 CS75 降级包（6 月版）', tags: ['系统包', '2019', '闲鱼获取'], path: xianyuUrl, marketplace: true, place: '购买后改名 update.zip → U 盘根目录', note: '购买时提供当前系统版本；只在确认适配后使用。' },
  { title: '2019 款 CS75 降级包（9 月版）', tags: ['系统包', '2019', '闲鱼获取'], path: xianyuUrl, marketplace: true, place: '购买后改名 update.zip → U 盘根目录', note: '与 6 月版二选一，不能作为同一次刷机的组合包。' },
  { title: '无网络急救包', tags: ['修复', '网络', '闲鱼获取'], path: xianyuUrl, marketplace: true, place: '购买后改名 update.zip → U 盘根目录', note: '仅用于网络异常；原说明要求按系统、MCU、4G 的顺序处理。' },
  { title: 'RE 文件管理器', tags: ['前置', 'APK'], path: '常用APP（降级成功后如果要安装第三方软件，记得先把里面的apk先都放进U盘根目录）/re.apk', place: 'U 盘根目录', note: '工程模式终端安装后，用它管理 U 盘与后续应用。' },
  { title: 'AutoKit 稳定基线版本', tags: ['CarPlay', 'APK'], path: '车机软件包/AutoKit_2022.11.15.1535.apk', place: 'U 盘根目录 → /sdcard/', note: 'v4 稳定方案指定此版本；不要和其他版本同时安装。' },
  { title: 'AutoKit v4 修复说明', tags: ['CarPlay', 'Root'], path: '解决方案v4/使用说明.txt', place: '脚本与 APK 复制到 /sdcard/', note: '先诊断、后修复；成功后做 3 次完全断电冷启动测试。' },
  { title: '车易联盒子固件（2025.04.17）', tags: ['CarPlay', '盒子固件', '闲鱼获取'], path: xianyuUrl, marketplace: true, place: '按盒子升级说明', note: '购买前确认盒子型号与当前版本，未知适配关系时不要升级。' },
  { title: '语音资源包', tags: ['修复', '语音', '闲鱼获取'], path: xianyuUrl, marketplace: true, place: '按语音异常步骤', note: '只在车机明确提示语音资源异常时处理。' },
];

const modelSteps = {
  '2018': { label: '2018 款 CS75 降级包', path: xianyuUrl },
  '2019-6': { label: '2019 款 6 月版降级包', path: xianyuUrl },
  '2019-9': { label: '2019 款 9 月版降级包', path: xianyuUrl },
};

const issueGuide = {
  downgrade: { title: '先完成降级和工程模式前置', text: '你的第一目标是让车机回到可进入工程模式的状态，不是同时安装所有软件。', steps: (model) => [`下载“${model.label}”。`, 'U 盘清空后，只放一个 update.zip 到第一层；不要解压。', '供电稳定时插入车机，按对应原始说明刷机。', '刷完后按页面的工程模式步骤安装 re.apk，再安装所需应用。'] },
  apps: { title: '先用 RE 管理器安装应用', text: '假设你已成功降级、能进入工程模式，且 su 命令可用。', steps: () => ['把 re.apk 与要安装的 APK 都放 U 盘根目录。', '按“工程模式 → 终端命令测试”步骤安装 re.apk 并重启。', '在 Root Explorer 中打开 /storage/udisk，每次只安装一个 APK。', '新导航优先从官方网站下载，再通过文件管理器安装。'] },
  carplay: { title: '先用低风险方案验证 CarPlay', text: '先确认 AutoKit 能启动、线材与盒子能连接，再部署自动修复。', steps: () => ['安装指定的 AutoKit_2022.11.15.1535.apk。', '先执行方案 A 的 quick_start.sh，验证它能正常拉起 AutoKit。', '若断电后仍闪退，再按 v4 说明先诊断、后修复。', '连续完成 3 次完全断电冷启动测试，才算稳定。'] },
  offline: { title: '网络异常：只处理网络问题', text: '不要把网络急救包当作通用降级包。', steps: () => ['按原说明先降级到 0522 版本。', '升级时不要全选，严格按：系统 → MCU → 4G。', '每一阶段完成后再继续；仍失败可能是主机硬件问题。'] },
  voice: { title: '语音异常：单独处理语音资源', text: '语音包不用于进入工程模式，也不是系统降级包。', steps: () => ['确认车机确实显示语音资源异常。', '只选择匹配的 iflytek 版本，不要与系统包混放。', '如无法确认版本，先停止并保留当前系统，避免盲刷。'] },
};

const byId = (id) => document.getElementById(id);
const linkHref = (path) => encodeURI(path);

function renderDownloads() {
  byId('downloadGrid').innerHTML = packages.map((item) => `
    <article class="download-card">
      <div class="card-meta">${item.tags.map((tag) => `<span class="pill">${tag}</span>`).join('')}</div>
      <h3>${item.title}</h3><p>${item.note}</p>
      <div class="placement"><span>放置位置</span><b>${item.place}</b></div>
      <a class="secondary-btn" href="${linkHref(item.path)}" ${item.marketplace ? 'target="_blank" rel="noopener"' : 'download'}>${item.marketplace ? '去闲鱼搜索 ikesman' : '下载文件'}</a>
    </article>`).join('');
}

function renderRecommendation() {
  const model = modelSteps[byId('modelSelect').value];
  const guide = issueGuide[byId('issueSelect').value];
  byId('recommendTitle').textContent = guide.title;
  byId('recommendText').textContent = guide.text;
  byId('recommendSteps').innerHTML = guide.steps(model).map((step) => `<li>${step}</li>`).join('');
  const firstLink = byId('issueSelect').value === 'downgrade' ? [{ ...xianyuLink, label: `获取 ${model.label}` }] : [];
  const extras = {
    apps: [{ label: '下载 re.apk', href: packages[4].path }], carplay: [{ label: '查看 v4 说明', href: packages[6].path }],
    offline: [{ ...xianyuLink, label: '获取网络急救包' }],
    voice: [{ ...xianyuLink, label: '获取语音资源包' }],
  }[byId('issueSelect').value] || [];
  byId('recommendLinks').innerHTML = [...firstLink, ...extras].map((link) => `<a class="secondary-btn" href="${linkHref(link.href)}" ${link.marketplace ? 'target="_blank" rel="noopener"' : 'download'}>${link.label}</a>`).join('');
}

byId('recommendBtn').addEventListener('click', renderRecommendation);
byId('modelSelect').addEventListener('change', renderRecommendation);
byId('issueSelect').addEventListener('change', renderRecommendation);
renderDownloads();
renderRecommendation();
