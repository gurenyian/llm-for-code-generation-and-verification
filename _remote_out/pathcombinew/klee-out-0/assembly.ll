; ModuleID = 'harness.bc'
source_filename = "harness_pathcombinew.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"PathCanonicalizeW_ret\00", align 1
@.str.1 = private unnamed_addr constant [20 x i8] c"PathIsRelativeW_ret\00", align 1
@.str.2 = private unnamed_addr constant [15 x i8] c"PathIsUNCW_ret\00", align 1
@.str.3 = private unnamed_addr constant [21 x i8] c"PathStripToRootW_ret\00", align 1
@.str.5 = private unnamed_addr constant [24 x i8] c"KERNELBASE_lstrlenW_ret\00", align 1
@.str.6 = private unnamed_addr constant [4 x i8] c"dir\00", align 1
@.str.7 = private unnamed_addr constant [5 x i8] c"file\00", align 1
@.str.8 = private unnamed_addr constant [18 x i8] c"PathCombineW_out0\00", align 1
@.str.9 = private unnamed_addr constant [24 x i8] c"myPathAddBackslashW_ret\00", align 1

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #0

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathCanonicalizeW(ptr noundef readnone %0) unnamed_addr #1 !dbg !15 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !27, metadata !DIExpression()), !dbg !28
  call void @llvm.dbg.value(metadata ptr %0, metadata !29, metadata !DIExpression()), !dbg !28
  %3 = icmp eq ptr %0, null
  br i1 %3, label %8, label %4, !dbg !30

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !31, metadata !DIExpression(DW_OP_deref)), !dbg !28
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str) #5, !dbg !32
  %5 = load i32, ptr %2, align 4, !dbg !33
  call void @llvm.dbg.value(metadata i32 %5, metadata !31, metadata !DIExpression()), !dbg !28
  call void @llvm.dbg.value(metadata i32 %5, metadata !31, metadata !DIExpression()), !dbg !28
  %6 = icmp ult i32 %5, 2, !dbg !34
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !35
  call void @llvm.dbg.value(metadata i32 undef, metadata !31, metadata !DIExpression()), !dbg !28
  br label %8, !dbg !36

8:                                                ; preds = %1, %4
  ret void, !dbg !37
}

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

declare void @klee_assume(i64 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind uwtable
define internal fastcc i32 @PathIsRelativeW() unnamed_addr #1 !dbg !38 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !41, metadata !DIExpression()), !dbg !42
  call void @llvm.dbg.value(metadata ptr %1, metadata !43, metadata !DIExpression(DW_OP_deref)), !dbg !42
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull @.str.1) #5, !dbg !44
  %2 = load i32, ptr %1, align 4, !dbg !45
  call void @llvm.dbg.value(metadata i32 %2, metadata !43, metadata !DIExpression()), !dbg !42
  %3 = icmp ult i32 %2, 2, !dbg !46
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !47
  call void @llvm.dbg.value(metadata i32 undef, metadata !43, metadata !DIExpression()), !dbg !42
  %5 = load i32, ptr %1, align 4, !dbg !48
  call void @llvm.dbg.value(metadata i32 %5, metadata !43, metadata !DIExpression()), !dbg !42
  ret i32 %5, !dbg !49
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc i32 @PathIsUNCW() unnamed_addr #1 !dbg !50 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !51, metadata !DIExpression()), !dbg !52
  call void @llvm.dbg.value(metadata ptr %1, metadata !53, metadata !DIExpression(DW_OP_deref)), !dbg !52
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull @.str.2) #5, !dbg !54
  %2 = load i32, ptr %1, align 4, !dbg !55
  call void @llvm.dbg.value(metadata i32 %2, metadata !53, metadata !DIExpression()), !dbg !52
  %3 = icmp ult i32 %2, 2, !dbg !56
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !57
  call void @llvm.dbg.value(metadata i32 undef, metadata !53, metadata !DIExpression()), !dbg !52
  %5 = load i32, ptr %1, align 4, !dbg !58
  call void @llvm.dbg.value(metadata i32 %5, metadata !53, metadata !DIExpression()), !dbg !52
  ret i32 %5, !dbg !59
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathStripToRootW(ptr noundef readnone %0) unnamed_addr #1 !dbg !60 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !63, metadata !DIExpression()), !dbg !64
  %3 = icmp eq ptr %0, null, !dbg !65
  br i1 %3, label %8, label %4, !dbg !67

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !68, metadata !DIExpression(DW_OP_deref)), !dbg !64
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.3) #5, !dbg !69
  %5 = load i32, ptr %2, align 4, !dbg !70
  call void @llvm.dbg.value(metadata i32 %5, metadata !68, metadata !DIExpression()), !dbg !64
  call void @llvm.dbg.value(metadata i32 %5, metadata !68, metadata !DIExpression()), !dbg !64
  %6 = icmp ult i32 %5, 2, !dbg !71
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !72
  call void @llvm.dbg.value(metadata i32 undef, metadata !68, metadata !DIExpression()), !dbg !64
  br label %8, !dbg !73

8:                                                ; preds = %1, %4
  ret void, !dbg !74
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc i32 @KERNELBASE_lstrlenW(ptr noundef readonly %0) unnamed_addr #1 !dbg !75 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !79, metadata !DIExpression()), !dbg !80
  %3 = icmp eq ptr %0, null, !dbg !81
  br i1 %3, label %14, label %4, !dbg !83

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !84, metadata !DIExpression(DW_OP_deref)), !dbg !80
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.5) #5, !dbg !85
  %5 = load i32, ptr %2, align 4, !dbg !86
  call void @llvm.dbg.value(metadata i32 %5, metadata !84, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.value(metadata i32 %5, metadata !84, metadata !DIExpression()), !dbg !80
  %6 = icmp ult i32 %5, 261, !dbg !87
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !88
  %8 = load i32, ptr %2, align 4, !dbg !89
  call void @llvm.dbg.value(metadata i32 %8, metadata !84, metadata !DIExpression()), !dbg !80
  %9 = icmp sgt i32 %8, 0, !dbg !91
  br i1 %9, label %10, label %14, !dbg !92

10:                                               ; preds = %4
  %11 = load i16, ptr %0, align 2, !dbg !93
  %12 = icmp ne i16 %11, 0, !dbg !94
  %13 = zext i1 %12 to i64
  call void @klee_assume(i64 noundef %13) #5, !dbg !95
  %.pre = load i32, ptr %2, align 4, !dbg !96
  br label %14, !dbg !95

14:                                               ; preds = %4, %10, %1
  %.0 = phi i32 [ 0, %1 ], [ %.pre, %10 ], [ %8, %4 ], !dbg !80
  ret i32 %.0, !dbg !97
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc ptr @PathCombineW(ptr noundef writeonly %0, ptr noundef readonly %1, ptr noundef %2) unnamed_addr #1 !dbg !98 {
  %4 = alloca [260 x i16], align 16
  call void @llvm.dbg.value(metadata ptr %0, metadata !102, metadata !DIExpression()), !dbg !103
  call void @llvm.dbg.value(metadata ptr %1, metadata !104, metadata !DIExpression()), !dbg !103
  call void @llvm.dbg.value(metadata ptr %2, metadata !105, metadata !DIExpression()), !dbg !103
  call void @llvm.dbg.value(metadata i32 0, metadata !106, metadata !DIExpression()), !dbg !103
  call void @llvm.dbg.value(metadata i32 0, metadata !107, metadata !DIExpression()), !dbg !103
  call void @llvm.dbg.declare(metadata ptr %4, metadata !108, metadata !DIExpression()), !dbg !112
  %.not = icmp eq ptr %0, null, !dbg !113
  br i1 %.not, label %31, label %5, !dbg !115

5:                                                ; preds = %3
  %6 = icmp ne ptr %1, null, !dbg !116
  %7 = icmp ne ptr %2, null
  %or.cond = or i1 %6, %7, !dbg !118
  br i1 %or.cond, label %9, label %8, !dbg !118

8:                                                ; preds = %5
  store i16 0, ptr %0, align 2, !dbg !119
  br label %31, !dbg !121

9:                                                ; preds = %5
  %.not7 = icmp eq ptr %2, null, !dbg !122
  br i1 %.not7, label %.thread22, label %10, !dbg !124

10:                                               ; preds = %9
  %11 = load i16, ptr %2, align 2, !dbg !125
  %12 = icmp eq i16 %11, 0, !dbg !125
  %cond20 = icmp eq ptr %1, null
  %or.cond27 = or i1 %cond20, %12, !dbg !126
  br i1 %or.cond27, label %.thread22, label %13, !dbg !126

13:                                               ; preds = %10
  %14 = load i16, ptr %1, align 2, !dbg !127
  %.not16 = icmp eq i16 %14, 0, !dbg !127
  br i1 %.not16, label %.thread22, label %15, !dbg !129

15:                                               ; preds = %13
  %16 = tail call fastcc i32 @PathIsRelativeW(), !dbg !130
  %.not17 = icmp eq i32 %16, 0, !dbg !130
  br i1 %.not17, label %17, label %.thread25, !dbg !131

17:                                               ; preds = %15
  %.pr = load i16, ptr %1, align 2, !dbg !132
  %.not13 = icmp eq i16 %.pr, 0, !dbg !132
  br i1 %.not13, label %.thread22, label %18, !dbg !135

18:                                               ; preds = %17
  %19 = load i16, ptr %2, align 2, !dbg !136
  %.not14 = icmp eq i16 %19, 92, !dbg !137
  br i1 %.not14, label %20, label %.thread22, !dbg !138

20:                                               ; preds = %18
  %21 = tail call fastcc i32 @PathIsUNCW(), !dbg !139
  %.not15 = icmp eq i32 %21, 0, !dbg !139
  br i1 %.not15, label %22, label %.thread22, !dbg !140

22:                                               ; preds = %20
  call void @llvm.dbg.value(metadata i32 undef, metadata !107, metadata !DIExpression()), !dbg !103
  call void @llvm.dbg.value(metadata i32 undef, metadata !106, metadata !DIExpression()), !dbg !103
  call fastcc void @PathStripToRootW(ptr noundef nonnull %4), !dbg !141
  %23 = getelementptr inbounds i16, ptr %2, i64 1, !dbg !146
  call void @llvm.dbg.value(metadata ptr %23, metadata !105, metadata !DIExpression()), !dbg !103
  br label %.thread25, !dbg !147

.thread25:                                        ; preds = %15, %22
  %.06 = phi ptr [ %23, %22 ], [ %2, %15 ]
  call void @llvm.dbg.value(metadata ptr %.06, metadata !105, metadata !DIExpression()), !dbg !103
  %24 = call fastcc ptr @myPathAddBackslashW(ptr noundef nonnull %4), !dbg !148
  %.not12 = icmp eq ptr %24, null, !dbg !148
  br i1 %.not12, label %30, label %25, !dbg !150

25:                                               ; preds = %.thread25
  %26 = call fastcc i32 @KERNELBASE_lstrlenW(ptr noundef nonnull %4), !dbg !151
  %27 = call fastcc i32 @KERNELBASE_lstrlenW(ptr noundef nonnull %.06), !dbg !152
  %28 = add nsw i32 %27, %26, !dbg !153
  %29 = icmp sgt i32 %28, 259, !dbg !154
  br i1 %29, label %30, label %.thread22, !dbg !155

30:                                               ; preds = %25, %.thread25
  store i16 0, ptr %0, align 2, !dbg !156
  br label %31, !dbg !158

.thread22:                                        ; preds = %9, %17, %18, %20, %13, %10, %25
  call fastcc void @PathCanonicalizeW(ptr noundef nonnull %4), !dbg !159
  br label %31, !dbg !160

31:                                               ; preds = %3, %.thread22, %30, %8
  %.0 = phi ptr [ null, %30 ], [ %0, %.thread22 ], [ null, %8 ], [ null, %3 ], !dbg !103
  ret ptr %.0, !dbg !161
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc ptr @myPathAddBackslashW(ptr noundef readnone %0) unnamed_addr #1 !dbg !162 {
  %2 = alloca ptr, align 8
  call void @llvm.dbg.value(metadata ptr %0, metadata !165, metadata !DIExpression()), !dbg !166
  %3 = icmp eq ptr %0, null, !dbg !167
  br i1 %3, label %11, label %4, !dbg !169

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !170, metadata !DIExpression(DW_OP_deref)), !dbg !166
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 8, ptr noundef nonnull @.str.9) #5, !dbg !171
  %5 = load ptr, ptr %2, align 8, !dbg !172
  call void @llvm.dbg.value(metadata ptr %5, metadata !170, metadata !DIExpression()), !dbg !166
  %6 = icmp eq ptr %5, %0, !dbg !173
  call void @llvm.dbg.value(metadata ptr %5, metadata !170, metadata !DIExpression()), !dbg !166
  %7 = icmp eq ptr %5, null, !dbg !174
  %8 = or i1 %6, %7, !dbg !174
  %9 = zext i1 %8 to i64
  call void @klee_assume(i64 noundef %9) #5, !dbg !175
  %10 = load ptr, ptr %2, align 8, !dbg !176
  call void @llvm.dbg.value(metadata ptr %10, metadata !170, metadata !DIExpression()), !dbg !166
  br label %11, !dbg !177

11:                                               ; preds = %1, %4
  %.0 = phi ptr [ %10, %4 ], [ null, %1 ], !dbg !166
  ret ptr %.0, !dbg !178
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !179 {
  %1 = alloca [260 x i16], align 16
  %2 = alloca [260 x i16], align 16
  %3 = alloca [260 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !182, metadata !DIExpression()), !dbg !183
  %4 = call ptr @memset(ptr %1, i32 0, i64 520), !dbg !183
  call void @llvm.dbg.declare(metadata ptr %2, metadata !184, metadata !DIExpression()), !dbg !185
  %5 = call ptr @memset(ptr %2, i32 0, i64 520), !dbg !185
  call void @llvm.dbg.declare(metadata ptr %3, metadata !186, metadata !DIExpression()), !dbg !187
  %6 = call ptr @memset(ptr %3, i32 0, i64 520), !dbg !187
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 520, ptr noundef nonnull @.str.6) #5, !dbg !188
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 520, ptr noundef nonnull @.str.7) #5, !dbg !189
  %7 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 259, !dbg !190
  %8 = load i16, ptr %7, align 2, !dbg !190
  %9 = icmp eq i16 %8, 0, !dbg !191
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !192
  %11 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 259, !dbg !193
  %12 = load i16, ptr %11, align 2, !dbg !193
  %13 = icmp eq i16 %12, 0, !dbg !194
  %14 = zext i1 %13 to i64
  call void @klee_assume(i64 noundef %14) #5, !dbg !195
  %15 = load i16, ptr %1, align 16, !dbg !196
  switch i16 %15, label %16 [
    i16 92, label %22
    i16 0, label %22
  ], !dbg !197

16:                                               ; preds = %0
  %17 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 1, !dbg !198
  %18 = load i16, ptr %17, align 2, !dbg !198
  %19 = icmp eq i16 %18, 58, !dbg !199
  br i1 %19, label %22, label %20, !dbg !200

20:                                               ; preds = %16
  %21 = icmp ugt i16 %15, 64, !dbg !201
  %phi.cast1 = zext i1 %21 to i64, !dbg !200
  br label %22, !dbg !200

22:                                               ; preds = %0, %0, %20, %16
  %23 = phi i64 [ 1, %16 ], [ 1, %0 ], [ %phi.cast1, %20 ], [ 1, %0 ]
  call void @klee_assume(i64 noundef %23) #5, !dbg !202
  %24 = load i16, ptr %2, align 16, !dbg !203
  switch i16 %24, label %25 [
    i16 92, label %31
    i16 0, label %31
  ], !dbg !204

25:                                               ; preds = %22
  %26 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 1, !dbg !205
  %27 = load i16, ptr %26, align 2, !dbg !205
  %28 = icmp eq i16 %27, 58, !dbg !206
  br i1 %28, label %31, label %29, !dbg !207

29:                                               ; preds = %25
  %30 = icmp ugt i16 %24, 64, !dbg !208
  %phi.cast2 = zext i1 %30 to i64, !dbg !207
  br label %31, !dbg !207

31:                                               ; preds = %22, %22, %29, %25
  %32 = phi i64 [ 1, %25 ], [ 1, %22 ], [ %phi.cast2, %29 ], [ 1, %22 ]
  call void @klee_assume(i64 noundef %32) #5, !dbg !209
  %33 = call fastcc ptr @PathCombineW(ptr noundef nonnull %3, ptr noundef nonnull %1, ptr noundef nonnull %2), !dbg !210
  call void @llvm.dbg.value(metadata ptr %33, metadata !211, metadata !DIExpression()), !dbg !212
  %.not = icmp eq ptr %33, null, !dbg !213
  br i1 %.not, label %37, label %34, !dbg !213

34:                                               ; preds = %31
  %35 = load i16, ptr %33, align 2, !dbg !214
  %36 = zext i16 %35 to i32, !dbg !214
  br label %37, !dbg !213

37:                                               ; preds = %31, %34
  %38 = phi i32 [ %36, %34 ], [ 0, %31 ], !dbg !213
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.8, i32 noundef %38) #5, !dbg !215
  ret i32 0, !dbg !216
}

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind writeonly uwtable
define dso_local ptr @memset(ptr noundef returned writeonly %0, i32 noundef %1, i64 noundef %2) local_unnamed_addr #3 !dbg !217 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !224, metadata !DIExpression()), !dbg !225
  call void @llvm.dbg.value(metadata i32 %1, metadata !226, metadata !DIExpression()), !dbg !225
  call void @llvm.dbg.value(metadata i64 %2, metadata !227, metadata !DIExpression()), !dbg !225
  call void @llvm.dbg.value(metadata ptr %0, metadata !228, metadata !DIExpression()), !dbg !225
  call void @llvm.dbg.value(metadata i64 %2, metadata !227, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !225
  %.not2 = icmp eq i64 %2, 0, !dbg !231
  br i1 %.not2, label %._crit_edge, label %.lr.ph, !dbg !232

.lr.ph:                                           ; preds = %3
  %4 = trunc i32 %1 to i8
  br label %5, !dbg !232

5:                                                ; preds = %.lr.ph, %5
  %.04 = phi ptr [ %0, %.lr.ph ], [ %7, %5 ]
  %.013 = phi i64 [ %2, %.lr.ph ], [ %6, %5 ]
  call void @llvm.dbg.value(metadata ptr %.04, metadata !228, metadata !DIExpression()), !dbg !225
  call void @llvm.dbg.value(metadata i64 %.013, metadata !227, metadata !DIExpression()), !dbg !225
  %6 = add i64 %.013, -1, !dbg !233
  call void @llvm.dbg.value(metadata i64 %6, metadata !227, metadata !DIExpression()), !dbg !225
  %7 = getelementptr inbounds i8, ptr %.04, i64 1, !dbg !234
  call void @llvm.dbg.value(metadata ptr %7, metadata !228, metadata !DIExpression()), !dbg !225
  store i8 %4, ptr %.04, align 1, !dbg !235
  call void @llvm.dbg.value(metadata i64 %6, metadata !227, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !225
  %.not = icmp eq i64 %6, 0, !dbg !231
  br i1 %.not, label %._crit_edge, label %5, !dbg !232, !llvm.loop !236

._crit_edge:                                      ; preds = %5, %3
  ret ptr %0, !dbg !239
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #0

; Function Attrs: argmemonly mustprogress nocallback nofree nounwind willreturn writeonly
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

attributes #0 = { nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #1 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind writeonly uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { argmemonly mustprogress nocallback nofree nounwind willreturn writeonly }
attributes #5 = { nounwind }

!llvm.dbg.cu = !{!0, !4}
!llvm.module.flags = !{!6, !7, !8, !9, !10, !11, !12}
!llvm.ident = !{!13, !14}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Ubuntu clang version 14.0.0-1ubuntu1.1", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "harness_pathcombinew.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "8bde79eb329f00ba3373f2f7822ef172")
!2 = !{!3}
!3 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!4 = distinct !DICompileUnit(language: DW_LANG_C99, file: !5, producer: "Ubuntu clang version 15.0.7", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!5 = !DIFile(filename: "/home/guren/klee/runtime/Freestanding/memset.c", directory: "/home/guren/klee/build/runtime/Freestanding", checksumkind: CSK_MD5, checksum: "f66ef9ef9131ab198e93a41b1a9ae1fc")
!6 = !{i32 7, !"Dwarf Version", i32 5}
!7 = !{i32 2, !"Debug Info Version", i32 3}
!8 = !{i32 1, !"wchar_size", i32 4}
!9 = !{i32 7, !"PIC Level", i32 2}
!10 = !{i32 7, !"PIE Level", i32 2}
!11 = !{i32 7, !"uwtable", i32 2}
!12 = !{i32 7, !"frame-pointer", i32 2}
!13 = !{!"Ubuntu clang version 14.0.0-1ubuntu1.1"}
!14 = !{!"Ubuntu clang version 15.0.7"}
!15 = distinct !DISubprogram(name: "PathCanonicalizeW", scope: !16, file: !16, line: 65, type: !17, scopeLine: 65, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!16 = !DIFile(filename: "./oda_stubs.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "8b8fc0bab9e9fc5f22bb7c506177de02")
!17 = !DISubroutineType(cc: DW_CC_nocall, types: !18)
!18 = !{!19, !21, !24}
!19 = !DIDerivedType(tag: DW_TAG_typedef, name: "BOOL", file: !16, line: 22, baseType: !20)
!20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !22, size: 64)
!22 = !DIDerivedType(tag: DW_TAG_typedef, name: "WCHAR", file: !16, line: 19, baseType: !23)
!23 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!24 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !25, size: 64)
!25 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !22)
!26 = !{}
!27 = !DILocalVariable(name: "buffer", arg: 1, scope: !15, file: !16, line: 65, type: !21)
!28 = !DILocation(line: 0, scope: !15)
!29 = !DILocalVariable(name: "path", arg: 2, scope: !15, file: !16, line: 65, type: !24)
!30 = !DILocation(line: 66, column: 9, scope: !15)
!31 = !DILocalVariable(name: "ret", scope: !15, file: !16, line: 68, type: !19)
!32 = !DILocation(line: 69, column: 5, scope: !15)
!33 = !DILocation(line: 70, column: 17, scope: !15)
!34 = !DILocation(line: 70, column: 29, scope: !15)
!35 = !DILocation(line: 70, column: 5, scope: !15)
!36 = !DILocation(line: 71, column: 5, scope: !15)
!37 = !DILocation(line: 72, column: 1, scope: !15)
!38 = distinct !DISubprogram(name: "PathIsRelativeW", scope: !16, file: !16, line: 82, type: !39, scopeLine: 82, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!39 = !DISubroutineType(cc: DW_CC_nocall, types: !40)
!40 = !{!19, !24}
!41 = !DILocalVariable(name: "path", arg: 1, scope: !38, file: !16, line: 82, type: !24)
!42 = !DILocation(line: 0, scope: !38)
!43 = !DILocalVariable(name: "ret", scope: !38, file: !16, line: 84, type: !19)
!44 = !DILocation(line: 85, column: 5, scope: !38)
!45 = !DILocation(line: 86, column: 17, scope: !38)
!46 = !DILocation(line: 86, column: 29, scope: !38)
!47 = !DILocation(line: 86, column: 5, scope: !38)
!48 = !DILocation(line: 87, column: 12, scope: !38)
!49 = !DILocation(line: 88, column: 1, scope: !38)
!50 = distinct !DISubprogram(name: "PathIsUNCW", scope: !16, file: !16, line: 98, type: !39, scopeLine: 98, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!51 = !DILocalVariable(name: "path", arg: 1, scope: !50, file: !16, line: 98, type: !24)
!52 = !DILocation(line: 0, scope: !50)
!53 = !DILocalVariable(name: "ret", scope: !50, file: !16, line: 100, type: !19)
!54 = !DILocation(line: 101, column: 5, scope: !50)
!55 = !DILocation(line: 102, column: 17, scope: !50)
!56 = !DILocation(line: 102, column: 29, scope: !50)
!57 = !DILocation(line: 102, column: 5, scope: !50)
!58 = !DILocation(line: 103, column: 12, scope: !50)
!59 = !DILocation(line: 104, column: 1, scope: !50)
!60 = distinct !DISubprogram(name: "PathStripToRootW", scope: !16, file: !16, line: 114, type: !61, scopeLine: 114, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!61 = !DISubroutineType(cc: DW_CC_nocall, types: !62)
!62 = !{!19, !21}
!63 = !DILocalVariable(name: "path", arg: 1, scope: !60, file: !16, line: 114, type: !21)
!64 = !DILocation(line: 0, scope: !60)
!65 = !DILocation(line: 115, column: 14, scope: !66)
!66 = distinct !DILexicalBlock(scope: !60, file: !16, line: 115, column: 9)
!67 = !DILocation(line: 115, column: 9, scope: !60)
!68 = !DILocalVariable(name: "ret", scope: !60, file: !16, line: 116, type: !19)
!69 = !DILocation(line: 117, column: 5, scope: !60)
!70 = !DILocation(line: 118, column: 17, scope: !60)
!71 = !DILocation(line: 118, column: 29, scope: !60)
!72 = !DILocation(line: 118, column: 5, scope: !60)
!73 = !DILocation(line: 119, column: 5, scope: !60)
!74 = !DILocation(line: 120, column: 1, scope: !60)
!75 = distinct !DISubprogram(name: "KERNELBASE_lstrlenW", scope: !16, file: !16, line: 170, type: !76, scopeLine: 170, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!76 = !DISubroutineType(types: !77)
!77 = !{!20, !78}
!78 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPCWSTR", file: !16, line: 20, baseType: !24)
!79 = !DILocalVariable(name: "str", arg: 1, scope: !75, file: !16, line: 170, type: !78)
!80 = !DILocation(line: 0, scope: !75)
!81 = !DILocation(line: 171, column: 13, scope: !82)
!82 = distinct !DILexicalBlock(scope: !75, file: !16, line: 171, column: 9)
!83 = !DILocation(line: 171, column: 9, scope: !75)
!84 = !DILocalVariable(name: "len", scope: !75, file: !16, line: 172, type: !20)
!85 = !DILocation(line: 173, column: 5, scope: !75)
!86 = !DILocation(line: 174, column: 17, scope: !75)
!87 = !DILocation(line: 174, column: 26, scope: !75)
!88 = !DILocation(line: 174, column: 5, scope: !75)
!89 = !DILocation(line: 175, column: 9, scope: !90)
!90 = distinct !DILexicalBlock(scope: !75, file: !16, line: 175, column: 9)
!91 = !DILocation(line: 175, column: 13, scope: !90)
!92 = !DILocation(line: 175, column: 9, scope: !75)
!93 = !DILocation(line: 175, column: 30, scope: !90)
!94 = !DILocation(line: 175, column: 37, scope: !90)
!95 = !DILocation(line: 175, column: 18, scope: !90)
!96 = !DILocation(line: 176, column: 12, scope: !75)
!97 = !DILocation(line: 177, column: 1, scope: !75)
!98 = distinct !DISubprogram(name: "PathCombineW", scope: !1, file: !1, line: 32, type: !99, scopeLine: 33, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!99 = !DISubroutineType(types: !100)
!100 = !{!101, !21, !24, !24}
!101 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPWSTR", file: !16, line: 21, baseType: !21)
!102 = !DILocalVariable(name: "dst", arg: 1, scope: !98, file: !1, line: 32, type: !21)
!103 = !DILocation(line: 0, scope: !98)
!104 = !DILocalVariable(name: "dir", arg: 2, scope: !98, file: !1, line: 32, type: !24)
!105 = !DILocalVariable(name: "file", arg: 3, scope: !98, file: !1, line: 32, type: !24)
!106 = !DILocalVariable(name: "use_both", scope: !98, file: !1, line: 34, type: !19)
!107 = !DILocalVariable(name: "strip", scope: !98, file: !1, line: 34, type: !19)
!108 = !DILocalVariable(name: "tmp", scope: !98, file: !1, line: 35, type: !109)
!109 = !DICompositeType(tag: DW_TAG_array_type, baseType: !22, size: 4160, elements: !110)
!110 = !{!111}
!111 = !DISubrange(count: 260)
!112 = !DILocation(line: 35, column: 11, scope: !98)
!113 = !DILocation(line: 37, column: 10, scope: !114)
!114 = distinct !DILexicalBlock(scope: !98, file: !1, line: 37, column: 9)
!115 = !DILocation(line: 37, column: 9, scope: !98)
!116 = !DILocation(line: 40, column: 10, scope: !117)
!117 = distinct !DILexicalBlock(scope: !98, file: !1, line: 40, column: 9)
!118 = !DILocation(line: 40, column: 14, scope: !117)
!119 = !DILocation(line: 42, column: 16, scope: !120)
!120 = distinct !DILexicalBlock(scope: !117, file: !1, line: 41, column: 5)
!121 = !DILocation(line: 43, column: 9, scope: !120)
!122 = !DILocation(line: 46, column: 11, scope: !123)
!123 = distinct !DILexicalBlock(scope: !98, file: !1, line: 46, column: 9)
!124 = !DILocation(line: 46, column: 16, scope: !123)
!125 = !DILocation(line: 46, column: 20, scope: !123)
!126 = !DILocation(line: 46, column: 27, scope: !123)
!127 = !DILocation(line: 50, column: 23, scope: !128)
!128 = distinct !DILexicalBlock(scope: !123, file: !1, line: 50, column: 14)
!129 = !DILocation(line: 50, column: 28, scope: !128)
!130 = !DILocation(line: 50, column: 32, scope: !128)
!131 = !DILocation(line: 50, column: 14, scope: !123)
!132 = !DILocation(line: 52, column: 22, scope: !133)
!133 = distinct !DILexicalBlock(scope: !134, file: !1, line: 52, column: 13)
!134 = distinct !DILexicalBlock(scope: !128, file: !1, line: 51, column: 5)
!135 = !DILocation(line: 52, column: 27, scope: !133)
!136 = !DILocation(line: 52, column: 30, scope: !133)
!137 = !DILocation(line: 52, column: 36, scope: !133)
!138 = !DILocation(line: 52, column: 44, scope: !133)
!139 = !DILocation(line: 52, column: 47, scope: !133)
!140 = !DILocation(line: 52, column: 13, scope: !134)
!141 = !DILocation(line: 70, column: 13, scope: !142)
!142 = distinct !DILexicalBlock(scope: !143, file: !1, line: 69, column: 9)
!143 = distinct !DILexicalBlock(scope: !144, file: !1, line: 68, column: 13)
!144 = distinct !DILexicalBlock(scope: !145, file: !1, line: 66, column: 5)
!145 = distinct !DILexicalBlock(scope: !98, file: !1, line: 65, column: 9)
!146 = !DILocation(line: 71, column: 17, scope: !142)
!147 = !DILocation(line: 72, column: 9, scope: !142)
!148 = !DILocation(line: 74, column: 14, scope: !149)
!149 = distinct !DILexicalBlock(scope: !144, file: !1, line: 74, column: 13)
!150 = !DILocation(line: 74, column: 39, scope: !149)
!151 = !DILocation(line: 74, column: 42, scope: !149)
!152 = !DILocation(line: 74, column: 69, scope: !149)
!153 = !DILocation(line: 74, column: 67, scope: !149)
!154 = !DILocation(line: 74, column: 95, scope: !149)
!155 = !DILocation(line: 74, column: 13, scope: !144)
!156 = !DILocation(line: 76, column: 20, scope: !157)
!157 = distinct !DILexicalBlock(scope: !149, file: !1, line: 75, column: 9)
!158 = !DILocation(line: 77, column: 13, scope: !157)
!159 = !DILocation(line: 83, column: 5, scope: !98)
!160 = !DILocation(line: 84, column: 5, scope: !98)
!161 = !DILocation(line: 85, column: 1, scope: !98)
!162 = distinct !DISubprogram(name: "myPathAddBackslashW", scope: !16, file: !16, line: 49, type: !163, scopeLine: 49, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !0, retainedNodes: !26)
!163 = !DISubroutineType(types: !164)
!164 = !{!101, !101}
!165 = !DILocalVariable(name: "lpszPath", arg: 1, scope: !162, file: !16, line: 49, type: !101)
!166 = !DILocation(line: 0, scope: !162)
!167 = !DILocation(line: 50, column: 18, scope: !168)
!168 = distinct !DILexicalBlock(scope: !162, file: !16, line: 50, column: 9)
!169 = !DILocation(line: 50, column: 9, scope: !162)
!170 = !DILocalVariable(name: "ret", scope: !162, file: !16, line: 51, type: !101)
!171 = !DILocation(line: 52, column: 5, scope: !162)
!172 = !DILocation(line: 53, column: 17, scope: !162)
!173 = !DILocation(line: 53, column: 21, scope: !162)
!174 = !DILocation(line: 53, column: 33, scope: !162)
!175 = !DILocation(line: 53, column: 5, scope: !162)
!176 = !DILocation(line: 54, column: 12, scope: !162)
!177 = !DILocation(line: 54, column: 5, scope: !162)
!178 = !DILocation(line: 55, column: 1, scope: !162)
!179 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 87, type: !180, scopeLine: 88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!180 = !DISubroutineType(types: !181)
!181 = !{!20}
!182 = !DILocalVariable(name: "dir", scope: !179, file: !1, line: 89, type: !109)
!183 = !DILocation(line: 89, column: 11, scope: !179)
!184 = !DILocalVariable(name: "file", scope: !179, file: !1, line: 90, type: !109)
!185 = !DILocation(line: 90, column: 11, scope: !179)
!186 = !DILocalVariable(name: "dst", scope: !179, file: !1, line: 91, type: !109)
!187 = !DILocation(line: 91, column: 11, scope: !179)
!188 = !DILocation(line: 93, column: 5, scope: !179)
!189 = !DILocation(line: 94, column: 5, scope: !179)
!190 = !DILocation(line: 96, column: 17, scope: !179)
!191 = !DILocation(line: 96, column: 33, scope: !179)
!192 = !DILocation(line: 96, column: 5, scope: !179)
!193 = !DILocation(line: 97, column: 17, scope: !179)
!194 = !DILocation(line: 97, column: 34, scope: !179)
!195 = !DILocation(line: 97, column: 5, scope: !179)
!196 = !DILocation(line: 103, column: 17, scope: !179)
!197 = !DILocation(line: 103, column: 29, scope: !179)
!198 = !DILocation(line: 103, column: 50, scope: !179)
!199 = !DILocation(line: 103, column: 57, scope: !179)
!200 = !DILocation(line: 103, column: 64, scope: !179)
!201 = !DILocation(line: 103, column: 74, scope: !179)
!202 = !DILocation(line: 103, column: 5, scope: !179)
!203 = !DILocation(line: 104, column: 17, scope: !179)
!204 = !DILocation(line: 104, column: 30, scope: !179)
!205 = !DILocation(line: 104, column: 52, scope: !179)
!206 = !DILocation(line: 104, column: 60, scope: !179)
!207 = !DILocation(line: 104, column: 67, scope: !179)
!208 = !DILocation(line: 104, column: 78, scope: !179)
!209 = !DILocation(line: 104, column: 5, scope: !179)
!210 = !DILocation(line: 107, column: 18, scope: !179)
!211 = !DILocalVariable(name: "out", scope: !179, file: !1, line: 107, type: !101)
!212 = !DILocation(line: 0, scope: !179)
!213 = !DILocation(line: 110, column: 42, scope: !179)
!214 = !DILocation(line: 110, column: 48, scope: !179)
!215 = !DILocation(line: 110, column: 5, scope: !179)
!216 = !DILocation(line: 112, column: 5, scope: !179)
!217 = distinct !DISubprogram(name: "memset", scope: !218, file: !218, line: 12, type: !219, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !4, retainedNodes: !26)
!218 = !DIFile(filename: "runtime/Freestanding/memset.c", directory: "/home/guren/klee", checksumkind: CSK_MD5, checksum: "f66ef9ef9131ab198e93a41b1a9ae1fc")
!219 = !DISubroutineType(types: !220)
!220 = !{!3, !3, !20, !221}
!221 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !222, line: 46, baseType: !223)
!222 = !DIFile(filename: "/usr/lib/llvm-15/lib/clang/15.0.7/include/stddef.h", directory: "", checksumkind: CSK_MD5, checksum: "b76978376d35d5cd171876ac58ac1256")
!223 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!224 = !DILocalVariable(name: "dst", arg: 1, scope: !217, file: !218, line: 12, type: !3)
!225 = !DILocation(line: 0, scope: !217)
!226 = !DILocalVariable(name: "s", arg: 2, scope: !217, file: !218, line: 12, type: !20)
!227 = !DILocalVariable(name: "count", arg: 3, scope: !217, file: !218, line: 12, type: !221)
!228 = !DILocalVariable(name: "a", scope: !217, file: !218, line: 13, type: !229)
!229 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !230, size: 64)
!230 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!231 = !DILocation(line: 14, column: 18, scope: !217)
!232 = !DILocation(line: 14, column: 3, scope: !217)
!233 = !DILocation(line: 14, column: 15, scope: !217)
!234 = !DILocation(line: 15, column: 7, scope: !217)
!235 = !DILocation(line: 15, column: 10, scope: !217)
!236 = distinct !{!236, !232, !237, !238}
!237 = !DILocation(line: 15, column: 12, scope: !217)
!238 = !{!"llvm.loop.mustprogress"}
!239 = !DILocation(line: 16, column: 3, scope: !217)
