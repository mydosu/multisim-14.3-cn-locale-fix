# Multisim 14.3 在中文 Windows 11 上「数据库无法访问」

启动 Multisim 14.3 时依次弹出三个框：

```
访问数据库时发生错误。
主数据库 无法访问。使用 主数据库 的功能将不可用。

访问数据库时发生错误。
企业数据库 无法访问。使用 企业数据库 的功能将不可用。

访问数据库时发生错误。
用户数据库 无法访问。使用 用户数据库 的功能将不可用。
```

点掉之后软件能开，但元件库是空的，等于不能用。**时好时坏**——同一台机器，上午能开、下午就弹，重装、重打补丁、重跑激活器都没用。

这是 NI 官方承认的一个兼容性缺陷，本文给出不改系统区域、不影响其它软件的解决办法。

## 原因

NI 知识库（`kA0VU000000DreP0AS`）写明：

> 该问题可能在中文原生版本的 Windows 11 操作系统中出现。由 Windows 更新 KB5065426 引起，该更新影响了 Windows 的区域设置（Locale）设为中文时的一些数据库相关的 dll 文件，而 Multisim 会调用这些 dll。
> 该问题已在 Circuit Design Suite **14.3.3** 中得到修正。

受影响的版本：**14.3.0 / 14.3.1 / 14.3.2**。

官方给的解法是升级到 14.3.3，或者把系统区域改成非中文。前者要重装整个套件（对非正版用户等于重来一遍），后者会让所有只认 GBK 的老程序乱码。

**本文的办法**：不动系统区域，只让 Multisim 这一个进程以 en-US 区域运行。

## 前提

- Multisim 14.3.0 / 14.3.1 / 14.3.2，装在 `C:\Program Files (x86)\National Instruments\Circuit Design Suite 14.3`
- Windows 10 / 11 中文版
- 全程用**管理员 PowerShell**

## 一、装 Locale Emulator Plus

**不要用 xupefei 原版 Locale Emulator。** 它 2.4.0.0 / 2.4.1.0 / 2.5.0.1 的发布包都缺 `LECommonLibrary.dll`，`LEProc.exe` 一启动就 `System.IO.FileNotFoundException` 崩溃。这是上游打包的问题，换代理重新下载也没用。

用仍在维护的分支 `julixian/LocaleEmulatorPlus`，包是完整的：

```powershell
.\scripts\1-install-locale-emulator.ps1
```

默认装到 `D:\Tools\LocaleEmulatorPlus`，可用 `-Dest` 改。

脚本做的事：下载 `LocaleEmulatorPlus.zip` → 解压 → 在同目录生成 `LEPConfig.xml`。

配置内容（关键是 `Location` 和 `RedirectRegistry`）：

```xml
<LEConfig>
  <Profiles>
    <Profile Name="English (United States)" Guid="3f2a9c11-7b4d-4a2e-9e8f-1c5d6b7a8e90" MainMenu="true">
      <Parameter></Parameter>
      <Location>en-US</Location>
      <Timezone>China Standard Time</Timezone>
      <RunAsAdmin>false</RunAsAdmin>
      <RedirectRegistry>true</RedirectRegistry>
      <IsAdvancedRedirection>false</IsAdvancedRedirection>
      <RunWithSuspend>false</RunWithSuspend>
    </Profile>
  </Profiles>
</LEConfig>
```

- 配置文件名是 `LEPConfig.xml`（Plus 分支改过名，不是原版的 `LEConfig.xml`），放在 `LEPProc_x86.exe` 同级目录。
- `LEProc` 取**第一个**全局 profile，所以文件里只放一个就行。
- Multisim 是 32 位程序，用 `LEPProc_x86.exe`。

## 二、接到开始菜单

```powershell
.\scripts\2-link-start-menu.ps1
```

把 `…\Start Menu\Programs\National Instruments\Circuit Design Suite 14.3\Multisim 14.3.lnk` 的目标改成：

```
Target : <安装目录>\LocaleEmulatorPlus\LEPProc_x86.exe
Args   : "C:\Program Files (x86)\National Instruments\Circuit Design Suite 14.3\multisim.exe"
```

图标保留 Multisim 原来的，所以你照旧点「Multisim 14.3」就行。原快捷方式备份成 `Multisim 14.3.lnk.orig`。

启动后会有一个 `LEPProc_x86.exe` 常驻后台，它是守着子进程的，Multisim 退出它会自己退。

## 三、中文界面（可选）

做完上面两步，数据库不弹了，但界面变成英文——**界面语言跟着 locale 走**：系统中文时读 `stringfiles\Chinese-simplified`，en-US 时读 `stringfiles\English`。

想让 en-US 下仍显示中文，把中文语言包合并进 `English` 目录：

```powershell
.\scripts\3-merge-chinese-strings.ps1
```

**必须逐条合并，不能整文件覆盖**，这是本文最值得记的一条经验。

`.ewstr` 是 UTF-16LE(BOM) 文本，每行 `ID=>文本<`。中文包比英文包**少一批 ID**（汉化基于更早的版本），如果直接把中文文件覆盖过去，缺失的 ID 会让程序把 ID 名本身当文本显示出来，界面上出现：

```
IDS_PROPPAGE_TRAN_FOR_INSTR_ID_STATIC4
IDS_SIM_SETUP_DLG_BUTTON
IDS_TITLE_INTERACTIVE
```

正确做法是以英文包为底，按 ID 把中文值替换进去，中文没有的 ID 保留英文原文。脚本就是这么做的（实测替换 21,824 条，合并后不存在以 `IDS_` 开头的值）。

原英文包备份成 `English.orig-en`。

## 已知限制：探针字体改不了

在 LE 下打开探针的字体对话框，选字体、点应用，**字体不会变**；先直接双击 `multisim.exe` 改好字体，再用 LE 启动，又变回默认。

原因和上面是同一个：LE 把进程的 ANSI 代码页从 936 改成 1252，系统里「宋体」「微软雅黑」这些中文字体名在 1252 下转换不出来，Multisim 创建字体时匹配失败。**这是硬冲突**——数据库需要英文代码页，字体需要中文代码页，同一个进程里只能二选一。

| 做法 | 结果 |
|---|---|
| 走 LE（本文方案） | 数据库稳定，字体只能用默认 |
| 不走 LE | 字体随便改，数据库偶发弹框，弹了重开一次 |
| 两个入口都留 | 两边不共享设置，改字体那次要直连 |

如果以后拿到 14.3.3 的补丁，升级才是根治——那时候这个仓库就没用了。

## 回滚

```powershell
.\scripts\9-rollback.ps1
```

恢复原快捷方式、恢复英文语言包。也可以手动：

- 快捷方式：把 `Multisim 14.3.lnk.orig` 复制回原位
- 语言包：用 `stringfiles\English.orig-en` 覆盖 `English`
- 想彻底不用 LE：删掉安装目录即可

## 验证过的环境

- Windows 11 25H2 中文版（Build 26200，系统区域 zh-CN，代码页 936）
- Circuit Design Suite 14.3.0（`ProductVersion 14.3.0.0`）
- 许可为 `permanent uncounted`，与数据库问题无关

## 参考

- NI KB：Multisim 提示 Problem accessing the database（`kA0VU000000DreP0AS`）
- NI KB：Problem Accessing the Database When Launching Multisim（`kA00Z0000019YLUSA2`）
- [julixian/LocaleEmulatorPlus](https://github.com/julixian/LocaleEmulatorPlus)

## License

脚本和文档 MIT。Locale Emulator Plus 是第三方软件，按它自己的许可证分发。
