## Lua+LÖVEにおける音源の暗号化・動的デコードによる不正利用防止

LÖVE（Love2D）の標準機能（`love.audio.newSource`）に音声ファイルのパスをそのまま渡すと、配布パッケージ（`.love`ファイルや通常のZIPアーカイブ）を解凍するだけで、中の音声素材（`.mp3`, `.wav`, `.ogg` など）を誰でも簡単に取り出すことができてしまいます。

これを防止するためには、**音源ファイルをあらかじめ暗号化（または独自のバイト変換）して保存しておき、ゲーム実行時にメモリ上で復号（デコード）して再生する**手法が有効です。

---

## 1. 処理の全体像

セキュリティとパフォーマンス（実行時の負荷）のバランスを考慮し、以下のフローを採用します。

1. **[事前準備] 暗号化ツールの作成:** 開発環境で、元の音声ファイルを暗号化ファイル（例: `.dat` や `.bin`）に変換するLuaスクリプトを実行する。
2. **[ゲーム実行時] メモリ上での復号:** ゲーム起動時またはロード時に、暗号化ファイルを `love.filesystem.read` でバイナリとして読み込み、メモリ上で復号（XOR演算など）を行う。
3. **[サウンド生成] FileData経由の読み込み:** 復号されたバイナリデータから `love.image.newFileData` や `love.sound.newDecoder` を介して `love.audio.newSource` を生成する。

---

## 2. 実装コード

### A. 【事前準備用】音源暗号化スクリプト (`encrypt.lua`)

ビルド前に手元のPC環境で実行し、暗号化された音声ファイルを生成するためのコードです。簡易かつ高速なXOR暗号（排他的論理和）を使用します。

```lua
-- encrypt.lua
local bit = require("bit") -- LuaJITのbitモジュールを使用

local function encryptFile(inputPath, outputPath, key)
    -- ファイルをバイナリモードで読み込み
    local inFile = io.open(inputPath, "rb")
    if not inFile then error("入力ファイルが見つかりません: " .. inputPath) end
    local content = inFile:read("*all")
    inFile:close()

    -- XOR暗号化処理
    local encryptedBytes = {}
    for i = 1, #content do
        local byte = string.byte(content, i)
        -- 簡易的な鍵処理（インデックスに応じて鍵を変化させると安全性が増します）
        local k = string.byte(key, ((i - 1) % #key) + 1)
        encryptedBytes[i] = string.char(bit.bxor(byte, k))
    end

    -- 暗号化ファイルの書き出し
    local outFile = io.open(outputPath, "wb")
    outFile:write(table.concat(encryptedBytes))
    outFile:close()
    print("暗号化完了: " .. outputPath)
end

-- 使い方: encryptFile("元ファイル", "出力ファイル", "暗号化キー")
encryptFile("assets/bgm.ogg", "assets/bgm.dat", "MySecretKey2026")

```

### B. 【ゲーム実装用】暗号化音源の読み込みと再生 (`main.lua`)

ゲーム実行時に、ファイルから暗号化データを読み込み、復号して再生可能にするコードです。

```lua
-- main.lua
local bit = require("bit")

-- 暗号化されたファイルをメモリ上で復号し、Sourceオブジェクトを返す関数
local function loadEncryptedSound(filepath, key, sourceType)
    -- LÖVEのファイルシステムからバイナリデータを取得
    local fileData, size = love.filesystem.read("data", filepath)
    if not fileData then error("ファイルが読み込めません: " .. filepath) end

    -- メモリ上で復号処理
    local decryptedBytes = {}
    for i = 1, size do
        local byte = string.byte(fileData, i)
        local k = string.byte(key, ((i - 1) % #key) + 1)
        decryptedBytes[i] = string.char(bit.bxor(byte, k))
    end
    local binaryStr = table.concat(decryptedBytes)

    -- 拡張子をダミー（または元の形式）で指定してFileDataを作成
    -- ※LÖVEがデコーダを識別できるようにするため、内部フォーマットに合わせる
    local dummyFilename = "sound.ogg" 
    local newFileData = love.filesystem.newFileData(binaryStr, dummyFilename)

    -- FileDataから音源（Source）を生成
    -- sourceType: BGMなら "stream"、SEなら "static" を指定
    local source = love.audio.newSource(newFileData, sourceType)
    return source
end

local bgm

function love.load()
    -- 暗号化されたファイルを読み込み、復号してセットアップ
    -- ※実際の製品ではキーを直接文字列で書かず、分割保持するなどの対策を推奨
    bgm = loadEncryptedSound("assets/bgm.dat", "MySecretKey2026", "stream")
    
    -- ループ再生を有効にして再生開始
    bgm:setLooping(true)
    bgm:play()
end

function love.draw()
    love.graphics.print("BGM再生中...（音源データはメモリ上でのみ復号されています）", 20, 20)
end

```

---

## 3. 運用・セキュリティ上の注意点とテクニック

### メモリ管理（Stream と Static の使い分け）

* **Static（効果音向け）:** `love.audio.newSource(data, "static")` は、復号された全データをメモリ（RAM）上に展開します。ロード時に一括して復号するため、再生時のCPU負荷はありませんが、ファイルサイズが大きいとメモリを圧迫します。
* **Stream（BGM向け）:** `love.audio.newSource(data, "stream")` は、再生しながら逐次デコードします。上記の実装では、一度暗号化ファイル全体を文字列としてメモリに読み込んで復号しているため、巨大すぎるファイル（数百MBの非圧縮WAVなど）を扱う場合は、ロード時のメモリ消費に注意してください。BGMには圧縮率の高い `.ogg` (Ogg Vorbis) 形式の使用を強く推奨します。

### 鍵（Key）の隠蔽

Luaのソースコードは、コンパイル（バイトコード化）しても比較的容易にデコンパイル可能です。暗号化キー（`MySecretKey2026` など）をそのままコードに記述していると、知識のあるユーザーには見破られます。

* **対策:** キーを複数の文字列に分割してゲーム内の別々のロジックに分散させ、実行時に結合して使用する、あるいは数式による計算結果をキーに変換するなどの難読化を施してください。

### より強固な保護（独自Cモジュールの導入）

XORではなく、より堅牢な暗号化（AESなど）を行いたい場合、純粋なLuaスクリプト（またはLuaJIT）だけでは処理速度が低下し、ゲーム起動時のフリーズ（ブロック）の原因になります。その場合は、C言語/C++で記述したLua用の暗号化拡張モジュール（`.dll` や `.so`）を自作・同梱し、復号処理をネイティブ側で行うことで、高速化と安全性の向上が両立できます。