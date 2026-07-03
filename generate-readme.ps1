# generate-readme.ps1

# 最初にスクリプトのディレクトリを特定
$scriptPath = $MyInvocation.MyCommand.Path
if ($scriptPath) {
    $scriptDir = Split-Path $scriptPath
} else {
    $scriptDir = (Get-Location).Path
}

$header = @"
# love-docs

Lua および LÖVE (LÖVE2D) に関するナレッジをまとめたリポジトリです。
主に Gemini から得た役立つ情報をスクラップしています。

## 目次

"@

$footer = @"
## 参考リンク

- [LÖVE 公式サイト](https://love2d.org/)
- [LÖVE 公式 Wiki (API リファレンス)](https://love2d.org/wiki/Main_Page_(%E6%97%A5%E6%9C%AC%E8%AA%9E))
- [Lua 公式サイト](https://www.lua.org/)
"@

# ドキュメントのあるディレクトリを取得 (隠しディレクトリや .git を除外)
$dirs = Get-ChildItem -Path $scriptDir -Directory | Where-Object { $_.Name -notlike ".*" }

$toc = ""
foreach ($dir in $dirs) {
    # フォルダ名を見出しに
    $toc += "### $($dir.Name)`r`n`r`n"
    
    # フォルダ内のmdファイルを取得
    $files = Get-ChildItem -Path $dir.FullName -Filter "*.md"
    foreach ($file in $files) {
        # 相対パスを作成してURL用に調整 (スペースを%20に置換、スラッシュ統一)
        $relativePath = "$($dir.Name)/$($file.Name)"
        $urlPath = $relativePath.Replace(" ", "%20").Replace("\", "/")
        
        $toc += "- [$($file.Name)]($urlPath)`r`n"
    }
    $toc += "`r`n"
}

# 全体のコンテンツを結合
$fullContent = $header + $toc + $footer

# README.md にUTF-8で保存する
$filePath = Join-Path $scriptDir "README.md"
$fullContent | Out-File -FilePath $filePath -Encoding utf8 -Force

Write-Host "README.md has been successfully updated with the table of contents."
