# gemini response

LÖVE（Love2D）で画面に文字を出力するには、主に `love.graphics.print` または `love.graphics.printf` という関数を使用します。

それぞれの関数の引数の意味や、文字を扱う上での重要なポイントを詳しく解説しますね。

---

## 1. 基本的な文字出力: `love.graphics.print`

もっともシンプルに文字列を描画する関数です。

```lua
love.graphics.print( text, x, y, r, sx, sy, ox, oy, kx, ky )
```

### 引数の詳細
* **`text`** (文字列/数値): 表示したい文字列。数値を入れても自動で文字列に変換されます。
* **`x`** (数値) `初期値: 0`: 描画を開始する画面の **X座標**（横位置）。
* **`y`** (数値) `初期値: 0`: 描画を開始する画面の **Y座標**（縦位置）。
* **`r`** (数値) `初期値: 0`: **回転角度**（ラジアン単位）。`math.rad(45)` のように指定すると45度回転します。
* **`sx`** (数値) `初期値: 1`: **横方向の拡大率**。`2` にすると横に2倍に伸びます。
* **`sy`** (数値) `初期値: sx`: **縦方向の拡大率**。省略すると `sx` と同じ値になります。
* **`ox`** (数値) `初期値: 0`: **原点のX座標（オフセット）**。回転や拡大の基準点となる位置を、文字列の左上からの相対距離で指定します。
* **`oy`** (数値) `初期値: 0`: **原点のY座標（オフセット）**。
* **`kx`** (数値) `初期値: 0`: 横方向の**傾き（シアー）**。文字を斜体にしたい時などに使います。
* **`ky`** (数値) `初期値: 0`: 縦方向の**傾き（シアー）**。

> 💡 **補足:** `x` と `y` 以外の引数は省略可能です。例えば、回転させずに拡大だけしたい場合は、`r` に `0` を指定する必要があります（`love.graphics.print("Hello", 100, 100, 0, 2, 2)`）。

---

## 2. 自動改行や揃えができる: `love.graphics.printf`

指定した幅で自動的に折り返したり、中央揃え・右揃えをしたい場合はこちらを使います（最後の「**f**」は formatted または flex の意味です）。

```lua
love.graphics.printf( text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky )
```

### 追加・変更された引数
* **`limit`** (数値): **折り返し位置の横幅**（ピクセル単位）。文字の長さがこの幅を超えると自動で改行されます。
* **`align`** (文字列) `初期値: "left"`: **文字の配置（アライメント）**。以下の4つから指定します。
    * `"left"` : 左揃え
    * `"center"` : 中央揃え
    * `"right"` : 右揃え
    * `"justify"` : 両端揃え（行の右端が綺麗に揃うようにスペースが調整されます）

---

## 3. 実装コードの例

実際に動かす時の標準的なコードは以下のようになります。

```lua
function love.draw()
    -- 1. 最もシンプルな出力
    love.graphics.print("Hello LÖVE!", 50, 50)

    -- 2. 大きさを2倍にして、45度回転させて出力
    -- (回転の中心を文字の左上にするため、x=200, y=200 の位置を基準に回ります)
    love.graphics.print("Rotated Text", 200, 200, math.rad(45), 2, 2)

    -- 3. 横幅300ピクセルで中央揃えにする出力
    love.graphics.printf("This is a long text that will automatically wrap when it reaches the limit.", 400, 50, 300, "center")
end
```

---

## ⚠️ 大事な注意点：日本語を表示したい場合

LÖVEのデフォルトのフォントは**日本語に対応していません**。デフォルトのまま日本語を表示しよううとすると、文字化け（いわゆる「豆腐（□）」現象）が起きます。

日本語を表示したい場合は、以下の手順で日本語フォント（`.ttf` や `.otf`）を読み込ませる必要があります。

```lua
local myFont

function love.load()
    -- フォントファイル（例: scorefont.ttf）とサイズ（32）を指定して読み込む
    -- ※フォントファイルは main.lua と同じフォルダ（またはサブフォルダ）に置いてください
    myFont = love.graphics.newFont("NotoSansJP-Regular.ttf", 32)
    
    -- ゲーム全体で使うフォントとしてセットする
    love.graphics.setFont(myFont)
end

function love.draw()
    love.graphics.print("こんにちは！日本語も表示できるよ。", 50, 50)
end
```

文字の表示位置の計算（例えば「画面の真ん中に文字をぴったり配置したい」など）で、フォントの縦幅・横幅を取得したい場合などはありますか？必要であればそのあたりの計算方法も解説できます！

---

# gemini response

LÖVE（Love2D）で文字を画面の真ん中にぴったり表示するには、**「画面の幅・高さ」と「描画する文字の幅・高さ」を取得して計算する**必要があります。

もっとも簡単かつ綺麗に中央配置ができる**2つの方法**を解説します。

---

## 方法1：`love.graphics.printf` を使う（おすすめ：横中央が簡単）

横方向の中央揃えに関しては、`printf` の機能を使うのが一番シンプルです。画面の左上（0, 0）から、画面全体の横幅いっぱいに枠を設定して `"center"` 配置にします。

```lua
function love.draw()
    -- 画面のサイズを取得
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- 現在設定されているフォントの縦幅（高さ）を取得
    local font = love.graphics.getFont()
    local text_height = font:getHeight()

    -- Y座標の計算：(画面の高さ - 文字の高さ) / 2
    local y = (screen_height - text_height) / 2

    -- 画面左端(x=0)から、画面全体の幅(limit=screen_width)を指定して中央揃え
    love.graphics.printf("画面の中央に表示", 0, y, screen_width, "center")
end
```

---

## 方法2：`love.graphics.print` + `font:getWidth()` を使う（縦横を厳密に計算）

文字の縦・横のピクセル数を正確に取得し、完全に計算だけで中央に配置する方法です。文字列の長さが動的に変わる場合や、回転・拡大も組み合わせたい場合に有効です。

```lua
function love.draw()
    -- 1. 画面のサイズを取得
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- 2. 表示したい文字列と、フォント情報を取得
    local text = "完全な中央配置"
    local font = love.graphics.getFont()

    -- 3. 文字列全体の横幅と縦幅（ピクセル）を取得
    local text_width = font:getWidth(text)
    local text_height = font:getHeight()

    -- 4. 中央にくる座標を計算
    -- (画面の半分) から (文字の半分のサイズ) を引く
    local x = (screen_width - text_width) / 2
    local y = (screen_height - text_height) / 2

    -- 5. 計算した座標で出力
    love.graphics.print(text, x, y)
end
```

### 💡 計算の考え方

なぜ `(画面の幅 - 文字の幅) / 2` で中央になるのかというと、下図のような関係になっているからです。



> `love.graphics.print` は指定した座標（左上）を基準に文字を描画するため、画面の中心座標（`screen_width / 2`）にそのまま文字を置くと、文字の左端が中心にきてしまい、右にズレてしまいます。そのため、文字の横幅の半分（`text_width / 2`）だけ左に押し戻す必要があり、結果として上記の計算式になります。

---

## おまけ：拡大（Scale）を考慮する場合の注意点

もし文字を2倍（`sx = 2, sy = 2`）などに拡大して表示する場合は、取得した文字のサイズも2倍にして計算しないとズレてしまいます。

```lua
-- 拡大率
local scale = 2

-- 座標計算（文字サイズに scale を掛ける）
local x = (screen_width - (text_width * scale)) / 2
local y = (screen_height - (text_height * scale)) / 2

-- 描画
love.graphics.print(text, x, y, 0, scale, scale)
```

この計算式は、文字だけでなく**画像（プログラミング上のSprite）を画面中央に表示したい時**にも全く同じように使えるので、覚えておくとゲーム作りのあらゆる場面で役立ちますよ！

文字のフォントサイズ変更や、他の図形との組み合わせなど、次に試してみたいことはありますか？