# SetGrid 参数自定义

加/删格点值或单位，**改两个文件，必须同步**：

## 一、加/删一个格点值

**`setgrid.form`**（界面）：加/删一个 checkbox 块

```
FIELD grid_0_25        ← 名 = grid_ + 数值，小数点换下划线（0.25→grid_0_25，1→grid_1）
FLOC 3 15              ← 位置（列 行）；现有两行在 y=11、13，新行放 y=15，放不下就下移/调 PORT
CHECKLIST "0.25"       ← 显示标签
ENDFIELD
```

**`setgrid.il`**（数值）：加/删列表里一行

```skill
("grid_0_25" 0.25)     ← key 必须和 FIELD 名一字不差；value 是实际间距
```

## 二、加/删一个单位

**`setgrid.form`**：加/删 `unit_xx` 那个 checkbox 块。

**`setgrid.il`**：加/删 `xfskill_grid_units` 里一行

```skill
("unit_in" "INCHES")   ← value 是 axlMKSConvert 大写单位：MILLIMETERS/MILS/MICRONS/INCHES/CENTIMETERS
```

加单位还想「打开时自动预选」，在 `xfskill_setgrid_init()` 里加：
```skill
((equal units "inches") (xfskill_select_unit gridForm "unit_in"))
```

## 三、生效

- `.form` 改动：**重启 Allegro**
- `.il` 改动：Command 窗 `skill load("E:/cadence_lib_xiaofeng/XFSKILL/plugins/setgrid/setgrid.il")`，再 `setgrid`
  （别用 `XFSKILL` 重载——加载器只加载一次）

## 四、注意

- **`FIELD` 名 = 列表 key**，区分大小写，对不上就点了没反应
- `.form` 注释用 `#`，**不是** `;`
- 控件不能重叠，放不下调 `FLOC` 行号 / `PORT` 高度
- 单位 value 必须大写；`axlMKSConvert` 第三参别传 `nil`（会换错成米，差 1000 倍）