# GrapheneHHG.jl

計算物理 春の学校 2026（後半2コマ）向けの、グラフェン 2 バンド TB + Peierls 位相 + GKSL + HHG の教材用リポジトリです。

`main` は受講者配布用の starter repo です。初期状態では TODO が残っているため、`Pkg.test()` と後半の examples はそのままでは通りません。

## セットアップ

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

## `main` でできること

- `using GrapheneHHG` は通ります
- スライドはレンダリングできます
- TODO の位置を確認しながら穴埋めを進められます

```bash
julia --project=. -e 'using GrapheneHHG'
quarto render docs/slides/slide.qmd
```

## checkpoint の使い方

学生向けの救済線は次の 4 段階です。

- `checkpoint-1-band`: `src/tb.jl` が埋まり、`examples/01_bands.jl` が動く
- `checkpoint-2-rhs`: `src/rhs.jl` が埋まり、`examples/02_timeevol_current.jl` と `Pkg.test()` が動く
- `checkpoint-4-fft`: `examples/03_hhg_fft.jl` が埋まり、HHG スペクトルが出る
- `checkpoint-5-selection`: `examples/04_selection_rule.jl` が埋まり、`Δ=0` / `Δ≠0` 比較が出る

詰まった場合は対応する tag に切り替えて続行します。

```bash
git switch --detach checkpoint-2-rhs
```

自力実装との差分は tag と `main` あるいは `solution-complete` を比較して確認します。

```bash
git diff main..checkpoint-2-rhs
git diff checkpoint-5-selection..solution-complete
```

## 完成版とテスト

完成版の退避点は `solution-complete` tag です。`Pkg.test()` を確実に通したい場合は、`checkpoint-2-rhs` 以降または `solution-complete` を使ってください。

```bash
git switch --detach solution-complete
julia --project=. -e 'using Pkg; Pkg.test()'
```

## examples

```bash
julia --project=. examples/01_bands.jl
julia --project=. examples/02_timeevol_current.jl
julia --project=. examples/03_hhg_fft.jl
julia --project=. examples/04_selection_rule.jl
```

生成画像は `examples/out/` に保存されます。4 本とも `CairoMakie` でそのまま保存でき、追加の GUI backend は不要です。`02`〜`04` の図は `Jx`/`Jy` の 2 成分を上下 2 段で表示します。

## スライド

```bash
quarto render docs/slides/slide.qmd
quarto render docs/slides
```

スライドの正規入口は `docs/slides/slide.qmd` です。本文は `docs/slides/_basic.qmd`, `docs/slides/_handson1.qmd`, `docs/slides/_handson2.qmd`, `docs/slides/_handson3.qmd`, `docs/slides/_handson4.qmd`, `docs/slides/_advanced.qmd` に分割しています。設定ファイルは `docs/slides/_quarto.yml` です。

GitHub Pages では `https://phjmsycc.github.io/CompPhys_School2026/slides/` で公開します。公開は `.github/workflows/pages-slides.yml` が担当し、`docs/slides/slide.qmd` を CI 上でレンダリングして Pages artifact を作成します。
