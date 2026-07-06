## LÖVE (Love2D) による爆発エフェクト（拡がる中空円）の実装手順

Lua と LÖVE を使用して、指定された「中央から消えていく、加算ブレンドの白い半透明な爆発エフェクト」を実装します。

この表現は、円の半径を大きくしながら、**「外側の円」から「一回り小さな内側の円」を `love.graphics.stencil`（ステンシルバッファ）を使ってくり抜いて描画する**ことで美しく再現できます。最後は内側の円が外側の円に追いつくことで、綺麗な外枠（リング状）のまま消滅します。

---

### 1. 実装コード (`main.lua`)

プロジェクトの `main.lua` に以下のコードを記述します。

```lua
-- 爆発エフェクトの管理テーブル
local explosion = {
    x = 0,
    y = 0,
    currentRadius = 0,    -- 現在の外半径
    maxRadius = 150,      -- 最大の大きさ
    innerRadius = 0,      -- 内側のくり抜き半径
    speed = 300,          -- 拡大速度（ピクセル/秒）
    alpha = 1.0,          -- 不透明度 (1.0 = 不透明, 0.0 = 透明)
    isActive = false      -- エフェクトが実行中かどうか
}

function love.load()
    -- 画面サイズの設定（任意）
    love.window.setMode(800, 600)
    love.window.setTitle("Explosion Effect Demo")
    
    -- 最初のアニメーションを開始（画面中央）
    triggerExplosion(400, 300)
end

function love.update(dt)
    if not explosion.isActive then return end

    -- 1. 外側の円を拡大
    if explosion.currentRadius < explosion.maxRadius then
        explosion.currentRadius = explosion.currentRadius + explosion.speed * dt
    else
        -- 2. 広がりきったら、内側の円（くり抜き用）を急速に拡大させる
        -- 外半径より少し遅れて追いつくように調整
        explosion.innerRadius = explosion.innerRadius + (explosion.speed * 1.5) * dt
        
        -- 3. 最後の方で徐々にフェードアウト（外枠が残る演出の補強）
        if explosion.innerRadius > explosion.maxRadius * 0.5 then
            explosion.alpha = explosion.alpha - 2.0 * dt
            if explosion.alpha < 0 then explosion.alpha = 0 end
        end
    end

    -- 終了判定（内円が外円に追いつく、または完全に透明になったら終了）
    if explosion.innerRadius >= explosion.currentRadius or explosion.alpha <= 0 then
        explosion.isActive = false
    end
end

function love.draw()
    -- 背景を暗くして、加算ブレンドを引き立たせる
    love.graphics.clear(0.1, 0.1, 0.15)

    if not explosion.isActive then 
        love.graphics.print("Click anywhere to explode!", 10, 10)
        return 
    end

    -- ステンシル関数の定義（内側の円の形にマスクを塗る）
    local function myStencilFunction()
        if explosion.innerRadius > 0 then
            love.graphics.circle("fill", explosion.x, explosion.y, explosion.innerRadius)
        end
    end

    -- ステンシルを設定
    love.graphics.stencil(myStencilFunction, "replace", 1)
    
    -- 「ステンシル値が 1 ではない（＝内側の円が描画されていない）部分のみ描画する」よう設定
    love.graphics.setStencilTest("less", 1)

    -- ブレンドモードを「加算 (add)」に変更
    love.graphics.setBlendMode("add")

    -- 白い半透明の円を描画（内側はステンシルによって自動的にくり抜かれる）
    love.graphics.setColor(1, 1, 1, explosion.alpha)
    love.graphics.circle("fill", explosion.x, explosion.y, explosion.currentRadius)

    -- グラフィックス状態のリセット
    love.graphics.setBlendMode("alpha")
    love.graphics.setStencilTest()
    love.graphics.setColor(1, 1, 1, 1)
end

-- マウスクリックで任意の場所に爆発を再発生させる
function love.mousepressed(x, y, button)
    if button == 1 then
        triggerExplosion(x, y)
    end
end

-- 爆発の初期化関数
function triggerExplosion(x, y)
    explosion.x = x
    explosion.y = y
    explosion.currentRadius = 0
    explosion.innerRadius = 0
    explosion.alpha = 1.0
    explosion.isActive = true
end

```

---

### 2. 表現テクニックの解説

#### ① ステンシルバッファ（くり抜き）の活用

`love.graphics.polygon` などでドーナツ型を作ることも可能ですが、LÖVE の `love.graphics.stencil` を使うのが最も滑らかで確実です。
まず `innerRadius` のサイズで目に見えないマスク（ステンシル）を描き、その部分を除外して `currentRadius` の円を描画することで、中央が綺麗に肉抜きされたリング状の表現になります。

#### ② 時間差による「外枠が残る」演出

`love.update` 内で、外側の円が最大サイズ (`maxRadius`) に達した瞬間から、内側の円の半径 (`innerRadius`) を外側以上のスピード (`speed * 1.5`) で追いかけさせています。これにより、中心から白い領域が消失していき、最終的に細い輪（外枠）だけが残って消滅する視覚効果を生み出します。

#### ③ 加算ブレンド (`"add"`)

`love.graphics.setBlendMode("add")` を適用することで、背後に別のオブジェクト（ゲームの自機や敵、背景など）があった場合、重なった部分のRGB値が加算され、発光しているようなリアルな爆発の質感を表現できます。