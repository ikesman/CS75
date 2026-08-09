"""
Phase 2 备用方案：分析 update.zip 结构
如果 Phase 1 失败，用此脚本分析固件修改可行性
"""
import zipfile, os, hashlib

UPDATE_ZIP = r'e:\project\CarPlay\update.zip'
EXTRACT_DIR = r'e:\project\CarPlay\_analysis\update_zip'

def analyze_update_zip():
    print("=" * 60)
    print("update.zip 结构分析")
    print("=" * 60)
    
    if not os.path.exists(UPDATE_ZIP):
        print(f"[!] 文件不存在: {UPDATE_ZIP}")
        return
    
    sz = os.path.getsize(UPDATE_ZIP)
    print(f"\n文件大小: {sz / 1024 / 1024:.1f} MB")
    
    with zipfile.ZipFile(UPDATE_ZIP, 'r') as z:
        names = z.namelist()
        print(f"总文件数: {len(names)}")
        
        # META-INF 分析
        meta_files = [n for n in names if n.startswith('META-INF/')]
        print(f"\nMETA-INF 文件 ({len(meta_files)}):")
        for f in meta_files:
            info = z.getinfo(f)
            print(f"  {f} ({info.file_size} bytes)")
        
        # 检查签名
        has_cert = any('CERT' in n for n in meta_files)
        has_manifest = 'META-INF/MANIFEST.MF' in names
        print(f"\n签名: CERT={'有' if has_cert else '无'}, MANIFEST={'有' if has_manifest else '无'}")
        
        # updater-script 分析
        updater_script = None
        for name in ['META-INF/com/google/android/updater-script',
                      'META-INF/com/google/android/update-script']:
            if name in names:
                updater_script = z.read(name).decode('utf-8', errors='replace')
                break
        
        if updater_script:
            print(f"\nupdater-script 长度: {len(updater_script)} 字符")
            
            # 分析关键操作
            lines = updater_script.split('\n')
            print(f"总行数: {len(lines)}")
            
            # 查找 mount/unmount
            mounts = [l.strip() for l in lines if 'mount(' in l or 'unmount(' in l]
            print(f"\n挂载操作 ({len(mounts)}):")
            for m in mounts[:10]:
                print(f"  {m[:100]}")
            
            # 查找 package_extract
            extracts = [l.strip() for l in lines if 'package_extract' in l]
            print(f"\n文件提取操作 ({len(extracts)}):")
            for e in extracts[:10]:
                print(f"  {e[:100]}")
            
            # 查找 assert/signature 验证
            asserts = [l.strip() for l in lines if 'assert(' in l or 'getprop(' in l]
            print(f"\n断言/验证 ({len(asserts)}):")
            for a in asserts[:10]:
                print(f"  {a[:100]}")
            
            # 查找与白名单相关的操作
            wl_ops = [l.strip() for l in lines if 'whitelist' in l.lower() or 'bootwhitelist' in l.lower()]
            print(f"\n白名单操作 ({len(wl_ops)}):")
            for w in wl_ops:
                print(f"  {w[:100]}")
            
            # 查找 priv-app 操作
            priv_ops = [l.strip() for l in lines if 'priv-app' in l]
            print(f"\npriv-app 操作 ({len(priv_ops)}):")
            for p in priv_ops[:10]:
                print(f"  {p[:100]}")
        
        # system 目录统计
        system_files = [n for n in names if n.startswith('system/')]
        system_size = sum(z.getinfo(n).file_size for n in system_files)
        print(f"\nsystem/ 文件: {len(system_files)} 个, 总大小 {system_size/1024/1024:.1f} MB")
        
        # priv-app 列表
        priv_apps = [n for n in names if 'priv-app' in n and n.endswith('.apk')]
        print(f"\npriv-app APK ({len(priv_apps)}):")
        for p in priv_apps:
            info = z.getinfo(p)
            print(f"  {os.path.basename(p)} ({info.file_size/1024:.0f} KB)")
    
    print(f"\n{'=' * 60}")
    print("如需修改固件，需要：")
    print("  1. 解压 update.zip")
    print("  2. 修改 system/usr/bootwhitelist.txt")
    print("  3. 添加 AutoKit.apk 到 system/priv-app/")
    print("  4. 修改 updater-script 添加对应的提取命令")
    print("  5. 重新打包并签名（需要 signapk 工具）")
    print("  6. 通过车机更新机制刷入")

if __name__ == '__main__':
    analyze_update_zip()
