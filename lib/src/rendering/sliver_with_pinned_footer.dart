import 'dart:math';

import 'package:flutter/rendering.dart';

// 创建一个具有固定底部的Sliver的渲染对象的父数据类
class RenderSliverWithPinnedFooterParentData extends ParentData with ContainerParentDataMixin<RenderObject> {}

// 实现一个自定义的RenderSliver，它能够将一个footer部件固定在滚动视图的底部。
class RenderSliverWithPinnedFooter extends RenderSliver with ContainerRenderObjectMixin<RenderObject, RenderSliverWithPinnedFooterParentData> {
  // 重写setupParentData以确保使用正确类型的parentData。
  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! RenderSliverWithPinnedFooterParentData) {
      child.parentData = RenderSliverWithPinnedFooterParentData();
    }
  }

  // 重写applyPaintTransform来调整footer的绘制转换，使其保持在视口的底部。
  @override
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    if (child == lastChild) {
      final geometry = this.geometry!;
      final footer = child as RenderBox;
      final footerTop = geometry.paintOrigin + geometry.paintExtent - footer.size.height;
      transform.translate(0.0, footerTop);
    }
  }

  // 确定RenderSliver和footer的布局。
  @override
  void performLayout() {
    final sliver = firstChild as RenderSliver;
    final footer = lastChild as RenderBox;
    sliver.layout(constraints, parentUsesSize: true);
    // 布局Sliver部分。
    footer.layout(constraints.asBoxConstraints(), parentUsesSize: true); // 布局footer部分。

    final double sliverPaintExtent = sliver.geometry!.paintExtent;
    final double sliverLayoutExtent = sliver.geometry!.layoutExtent;
    final double sliverMaxPaintExtent = sliver.geometry!.maxPaintExtent;
    final double footerHeight = footer.size.height.ceilToDouble();
    final double maxPaintExtent = sliverMaxPaintExtent + footerHeight;

    // 计算footer范围
    final footerExtent = calculatePaintOffset(constraints, from: sliverMaxPaintExtent, to: maxPaintExtent).ceilToDouble();
    final footerCacheExtent = calculateCacheOffset(constraints, from: sliverMaxPaintExtent, to: maxPaintExtent).ceilToDouble();

    final paintExtent = min(constraints.remainingPaintExtent, sliverPaintExtent + footerExtent);
    final layoutExtent = min(constraints.remainingPaintExtent, sliverLayoutExtent + footerExtent);
    final cacheExtent = min(constraints.remainingPaintExtent, sliver.geometry!.cacheExtent + footerCacheExtent);

    // 设置当前RenderSliver的几何属性。
    geometry = SliverGeometry(
      scrollExtent: sliver.geometry!.scrollExtent + footerHeight, // 总滚动范围。
      paintExtent: paintExtent, // 绘制范围。
      paintOrigin: sliver.geometry!.paintOrigin, // 绘制起点。
      layoutExtent: layoutExtent, // 布局范围。
      maxPaintExtent: maxPaintExtent, // 最大绘制范围。
      maxScrollObstructionExtent: sliver.geometry!.maxScrollObstructionExtent, // 最大滚动阻塞范围。
      hitTestExtent: paintExtent, // 点击测试范围。
      visible: sliver.geometry!.visible, // 是否可见。
      hasVisualOverflow: sliver.geometry!.hasVisualOverflow, // 是否有视觉溢出。
      scrollOffsetCorrection: sliver.geometry!.scrollOffsetCorrection, // 滚动偏移校正。
      cacheExtent: cacheExtent, // 缓存范围。
    );
  }

  // 重写hitTestChildren来处理子部件的点击事件。
  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    double? mainAxisPosition,
    double? crossAxisPosition,
  }) {
    if (mainAxisPosition == null || crossAxisPosition == null) return false;

    final geometry = this.geometry!;
    final sliver = firstChild as RenderSliver;
    final footer = lastChild as RenderBox;
    final footerTop = geometry.paintOrigin + geometry.paintExtent - footer.size.height;
    // 如果点击位置在footer内，则先进行footer的点击测试。
    if (mainAxisPosition >= footerTop) {
      final hit = footer.hitTest(
        BoxHitTestResult.wrap(result),
        position: Offset(crossAxisPosition, mainAxisPosition - footerTop),
      );
      if (hit) {
        return true;
      }
    }
    // 若不在footer内，或footer没有处理点击事件，则进行sliver部分的点击测试。
    return sliver.hitTest(
      result,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );
  }

  // 重写paint方法来绘制sliver和footer。
  @override
  void paint(PaintingContext context, Offset offset) {
    final geometry = this.geometry!;

    final sliver = firstChild as RenderSliver;
    final footer = lastChild as RenderBox;
    // 先绘制sliver部分。
    context.paintChild(sliver, offset);
    // 然后绘制footer部分，footer固定在底部。
    context.paintChild(
      footer,
      Offset(
        offset.dx,
        offset.dy + geometry.paintOrigin + geometry.paintExtent - footer.size.height,
      ),
    );
  }
}
