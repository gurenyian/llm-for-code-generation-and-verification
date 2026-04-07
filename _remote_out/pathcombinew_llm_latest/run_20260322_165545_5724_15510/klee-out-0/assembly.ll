; ModuleID = 'harness.bc'
source_filename = "harness_pathcombinew.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str.2 = private unnamed_addr constant [20 x i8] c"PathIsRelativeW_ret\00", align 1
@.str.3 = private unnamed_addr constant [15 x i8] c"PathIsUNCW_ret\00", align 1
@.str.4 = private unnamed_addr constant [21 x i8] c"PathStripToRootW_ret\00", align 1
@.str.5 = private unnamed_addr constant [24 x i8] c"KERNELBASE_lstrlenW_ret\00", align 1
@.str.6 = private unnamed_addr constant [4 x i8] c"dir\00", align 1
@.str.7 = private unnamed_addr constant [5 x i8] c"file\00", align 1
@.str.8 = private unnamed_addr constant [18 x i8] c"PathCombineW_out0\00", align 1

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #0

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #1

declare void @klee_assume(i64 noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind uwtable
define internal fastcc i32 @PathIsRelativeW() unnamed_addr #2 !dbg !15 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !26, metadata !DIExpression()), !dbg !27
  call void @llvm.dbg.value(metadata ptr %1, metadata !28, metadata !DIExpression(DW_OP_deref)), !dbg !27
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull @.str.2) #5, !dbg !29
  %2 = load i32, ptr %1, align 4, !dbg !30
  call void @llvm.dbg.value(metadata i32 %2, metadata !28, metadata !DIExpression()), !dbg !27
  %3 = icmp ult i32 %2, 2, !dbg !31
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !32
  call void @llvm.dbg.value(metadata i32 undef, metadata !28, metadata !DIExpression()), !dbg !27
  %5 = load i32, ptr %1, align 4, !dbg !33
  call void @llvm.dbg.value(metadata i32 %5, metadata !28, metadata !DIExpression()), !dbg !27
  ret i32 %5, !dbg !34
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc i32 @PathIsUNCW() unnamed_addr #2 !dbg !35 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !36, metadata !DIExpression()), !dbg !37
  call void @llvm.dbg.value(metadata ptr %1, metadata !38, metadata !DIExpression(DW_OP_deref)), !dbg !37
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull @.str.3) #5, !dbg !39
  %2 = load i32, ptr %1, align 4, !dbg !40
  call void @llvm.dbg.value(metadata i32 %2, metadata !38, metadata !DIExpression()), !dbg !37
  %3 = icmp ult i32 %2, 2, !dbg !41
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !42
  call void @llvm.dbg.value(metadata i32 undef, metadata !38, metadata !DIExpression()), !dbg !37
  %5 = load i32, ptr %1, align 4, !dbg !43
  call void @llvm.dbg.value(metadata i32 %5, metadata !38, metadata !DIExpression()), !dbg !37
  ret i32 %5, !dbg !44
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathStripToRootW(ptr noundef readnone %0) unnamed_addr #2 !dbg !45 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !49, metadata !DIExpression()), !dbg !50
  %3 = icmp eq ptr %0, null, !dbg !51
  br i1 %3, label %8, label %4, !dbg !53

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !54, metadata !DIExpression(DW_OP_deref)), !dbg !50
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.4) #5, !dbg !55
  %5 = load i32, ptr %2, align 4, !dbg !56
  call void @llvm.dbg.value(metadata i32 %5, metadata !54, metadata !DIExpression()), !dbg !50
  call void @llvm.dbg.value(metadata i32 %5, metadata !54, metadata !DIExpression()), !dbg !50
  %6 = icmp ult i32 %5, 2, !dbg !57
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !58
  call void @llvm.dbg.value(metadata i32 undef, metadata !54, metadata !DIExpression()), !dbg !50
  br label %8, !dbg !59

8:                                                ; preds = %1, %4
  ret void, !dbg !60
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc i32 @KERNELBASE_lstrlenW(ptr noundef readonly %0) unnamed_addr #2 !dbg !61 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !65, metadata !DIExpression()), !dbg !66
  %3 = icmp eq ptr %0, null, !dbg !67
  br i1 %3, label %14, label %4, !dbg !69

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !70, metadata !DIExpression(DW_OP_deref)), !dbg !66
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.5) #5, !dbg !71
  %5 = load i32, ptr %2, align 4, !dbg !72
  call void @llvm.dbg.value(metadata i32 %5, metadata !70, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata i32 %5, metadata !70, metadata !DIExpression()), !dbg !66
  %6 = icmp ult i32 %5, 261, !dbg !73
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !74
  %8 = load i32, ptr %2, align 4, !dbg !75
  call void @llvm.dbg.value(metadata i32 %8, metadata !70, metadata !DIExpression()), !dbg !66
  %9 = icmp sgt i32 %8, 0, !dbg !77
  br i1 %9, label %10, label %14, !dbg !78

10:                                               ; preds = %4
  %11 = load i16, ptr %0, align 2, !dbg !79
  %12 = icmp ne i16 %11, 0, !dbg !80
  %13 = zext i1 %12 to i64
  call void @klee_assume(i64 noundef %13) #5, !dbg !81
  %.pre = load i32, ptr %2, align 4, !dbg !82
  br label %14, !dbg !81

14:                                               ; preds = %4, %10, %1
  %.0 = phi i32 [ 0, %1 ], [ %.pre, %10 ], [ %8, %4 ], !dbg !66
  ret i32 %.0, !dbg !83
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc ptr @PathCombineW(ptr noundef %0, ptr noundef readonly %1, ptr noundef %2) unnamed_addr #2 !dbg !84 {
  %4 = alloca [260 x i16], align 16
  call void @llvm.dbg.value(metadata ptr %0, metadata !88, metadata !DIExpression()), !dbg !89
  call void @llvm.dbg.value(metadata ptr %1, metadata !90, metadata !DIExpression()), !dbg !89
  call void @llvm.dbg.value(metadata ptr %2, metadata !91, metadata !DIExpression()), !dbg !89
  call void @llvm.dbg.value(metadata i32 0, metadata !92, metadata !DIExpression()), !dbg !89
  call void @llvm.dbg.value(metadata i32 0, metadata !93, metadata !DIExpression()), !dbg !89
  call void @llvm.dbg.declare(metadata ptr %4, metadata !94, metadata !DIExpression()), !dbg !98
  %.not = icmp eq ptr %0, null, !dbg !99
  br i1 %.not, label %34, label %5, !dbg !101

5:                                                ; preds = %3
  %6 = icmp ne ptr %1, null, !dbg !102
  %7 = icmp ne ptr %2, null
  %or.cond = or i1 %6, %7, !dbg !104
  br i1 %or.cond, label %9, label %8, !dbg !104

8:                                                ; preds = %5
  store i16 0, ptr %0, align 2, !dbg !105
  br label %34, !dbg !107

9:                                                ; preds = %5
  %.not7 = icmp eq ptr %2, null, !dbg !108
  br i1 %.not7, label %.thread22, label %10, !dbg !110

10:                                               ; preds = %9
  %11 = load i16, ptr %2, align 2, !dbg !111
  %12 = icmp eq i16 %11, 0, !dbg !111
  %cond20 = icmp eq ptr %1, null
  %or.cond27 = or i1 %cond20, %12, !dbg !112
  br i1 %or.cond27, label %.thread22, label %13, !dbg !112

13:                                               ; preds = %10
  %14 = load i16, ptr %1, align 2, !dbg !113
  %.not16 = icmp eq i16 %14, 0, !dbg !113
  br i1 %.not16, label %.thread22, label %15, !dbg !115

15:                                               ; preds = %13
  %16 = tail call fastcc i32 @PathIsRelativeW(), !dbg !116
  %.not17 = icmp eq i32 %16, 0, !dbg !116
  br i1 %.not17, label %17, label %.thread25, !dbg !117

17:                                               ; preds = %15
  %.pr = load i16, ptr %1, align 2, !dbg !118
  %.not13 = icmp eq i16 %.pr, 0, !dbg !118
  br i1 %.not13, label %.thread22, label %18, !dbg !121

18:                                               ; preds = %17
  %19 = load i16, ptr %2, align 2, !dbg !122
  %.not14 = icmp eq i16 %19, 92, !dbg !123
  br i1 %.not14, label %20, label %.thread22, !dbg !124

20:                                               ; preds = %18
  %21 = tail call fastcc i32 @PathIsUNCW(), !dbg !125
  %.not15 = icmp eq i32 %21, 0, !dbg !125
  br i1 %.not15, label %22, label %.thread22, !dbg !126

22:                                               ; preds = %20
  call void @llvm.dbg.value(metadata i32 undef, metadata !93, metadata !DIExpression()), !dbg !89
  call void @llvm.dbg.value(metadata i32 undef, metadata !92, metadata !DIExpression()), !dbg !89
  call fastcc void @PathStripToRootW(ptr noundef nonnull %4), !dbg !127
  %23 = getelementptr inbounds i16, ptr %2, i64 1, !dbg !132
  call void @llvm.dbg.value(metadata ptr %23, metadata !91, metadata !DIExpression()), !dbg !89
  br label %.thread25, !dbg !133

.thread25:                                        ; preds = %15, %22
  %.06 = phi ptr [ %23, %22 ], [ %2, %15 ]
  call void @llvm.dbg.value(metadata ptr %.06, metadata !91, metadata !DIExpression()), !dbg !89
  %24 = call i32 (ptr, ...) @myPathAddBackslashW(ptr noundef nonnull %4) #5, !dbg !134
  %.not12 = icmp eq i32 %24, 0, !dbg !134
  br i1 %.not12, label %30, label %25, !dbg !136

25:                                               ; preds = %.thread25
  %26 = call fastcc i32 @KERNELBASE_lstrlenW(ptr noundef nonnull %4), !dbg !137
  %27 = call fastcc i32 @KERNELBASE_lstrlenW(ptr noundef nonnull %.06), !dbg !138
  %28 = add nsw i32 %27, %26, !dbg !139
  %29 = icmp sgt i32 %28, 259, !dbg !140
  br i1 %29, label %30, label %31, !dbg !141

30:                                               ; preds = %25, %.thread25
  store i16 0, ptr %0, align 2, !dbg !142
  br label %34, !dbg !144

31:                                               ; preds = %25
  %32 = call i32 (ptr, ptr, ...) @lstrcatW(ptr noundef nonnull %4, ptr noundef nonnull %.06) #5, !dbg !145
  br label %.thread22, !dbg !146

.thread22:                                        ; preds = %9, %17, %18, %20, %13, %10, %31
  %33 = call i32 (ptr, ptr, ...) @PathCanonicalizeW(ptr noundef nonnull %0, ptr noundef nonnull %4) #5, !dbg !147
  br label %34, !dbg !148

34:                                               ; preds = %3, %.thread22, %30, %8
  %.0 = phi ptr [ null, %30 ], [ %0, %.thread22 ], [ null, %8 ], [ null, %3 ], !dbg !89
  ret ptr %.0, !dbg !149
}

declare i32 @myPathAddBackslashW(...) local_unnamed_addr #1

declare i32 @lstrcatW(...) local_unnamed_addr #1

declare i32 @PathCanonicalizeW(...) local_unnamed_addr #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #2 !dbg !150 {
  %1 = alloca [260 x i16], align 16
  %2 = alloca [260 x i16], align 16
  %3 = alloca [260 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !153, metadata !DIExpression()), !dbg !154
  %4 = call ptr @memset(ptr %1, i32 0, i64 520), !dbg !154
  call void @llvm.dbg.declare(metadata ptr %2, metadata !155, metadata !DIExpression()), !dbg !156
  %5 = call ptr @memset(ptr %2, i32 0, i64 520), !dbg !156
  call void @llvm.dbg.declare(metadata ptr %3, metadata !157, metadata !DIExpression()), !dbg !158
  %6 = call ptr @memset(ptr %3, i32 0, i64 520), !dbg !158
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 520, ptr noundef nonnull @.str.6) #5, !dbg !159
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 520, ptr noundef nonnull @.str.7) #5, !dbg !160
  %7 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 259, !dbg !161
  %8 = load i16, ptr %7, align 2, !dbg !161
  %9 = icmp eq i16 %8, 0, !dbg !162
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !163
  %11 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 259, !dbg !164
  %12 = load i16, ptr %11, align 2, !dbg !164
  %13 = icmp eq i16 %12, 0, !dbg !165
  %14 = zext i1 %13 to i64
  call void @klee_assume(i64 noundef %14) #5, !dbg !166
  %15 = load i16, ptr %1, align 16, !dbg !167
  switch i16 %15, label %16 [
    i16 92, label %22
    i16 0, label %22
  ], !dbg !168

16:                                               ; preds = %0
  %17 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 1, !dbg !169
  %18 = load i16, ptr %17, align 2, !dbg !169
  %19 = icmp eq i16 %18, 58, !dbg !170
  br i1 %19, label %22, label %20, !dbg !171

20:                                               ; preds = %16
  %21 = icmp ugt i16 %15, 64, !dbg !172
  %phi.cast1 = zext i1 %21 to i64, !dbg !171
  br label %22, !dbg !171

22:                                               ; preds = %0, %0, %20, %16
  %23 = phi i64 [ 1, %16 ], [ 1, %0 ], [ %phi.cast1, %20 ], [ 1, %0 ]
  call void @klee_assume(i64 noundef %23) #5, !dbg !173
  %24 = load i16, ptr %2, align 16, !dbg !174
  switch i16 %24, label %25 [
    i16 92, label %31
    i16 0, label %31
  ], !dbg !175

25:                                               ; preds = %22
  %26 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 1, !dbg !176
  %27 = load i16, ptr %26, align 2, !dbg !176
  %28 = icmp eq i16 %27, 58, !dbg !177
  br i1 %28, label %31, label %29, !dbg !178

29:                                               ; preds = %25
  %30 = icmp ugt i16 %24, 64, !dbg !179
  %phi.cast2 = zext i1 %30 to i64, !dbg !178
  br label %31, !dbg !178

31:                                               ; preds = %22, %22, %29, %25
  %32 = phi i64 [ 1, %25 ], [ 1, %22 ], [ %phi.cast2, %29 ], [ 1, %22 ]
  call void @klee_assume(i64 noundef %32) #5, !dbg !180
  %33 = call fastcc ptr @PathCombineW(ptr noundef nonnull %3, ptr noundef nonnull %1, ptr noundef nonnull %2), !dbg !181
  call void @llvm.dbg.value(metadata ptr %33, metadata !182, metadata !DIExpression()), !dbg !183
  %.not = icmp eq ptr %33, null, !dbg !184
  br i1 %.not, label %37, label %34, !dbg !184

34:                                               ; preds = %31
  %35 = load i16, ptr %33, align 2, !dbg !185
  %36 = zext i16 %35 to i32, !dbg !185
  br label %37, !dbg !184

37:                                               ; preds = %31, %34
  %38 = phi i32 [ %36, %34 ], [ 0, %31 ], !dbg !184
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.8, i32 noundef %38) #5, !dbg !186
  ret i32 0, !dbg !187
}

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #1

; Function Attrs: nofree noinline norecurse nosync nounwind writeonly uwtable
define dso_local ptr @memset(ptr noundef returned writeonly %0, i32 noundef %1, i64 noundef %2) local_unnamed_addr #3 !dbg !188 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !195, metadata !DIExpression()), !dbg !196
  call void @llvm.dbg.value(metadata i32 %1, metadata !197, metadata !DIExpression()), !dbg !196
  call void @llvm.dbg.value(metadata i64 %2, metadata !198, metadata !DIExpression()), !dbg !196
  call void @llvm.dbg.value(metadata ptr %0, metadata !199, metadata !DIExpression()), !dbg !196
  call void @llvm.dbg.value(metadata i64 %2, metadata !198, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !196
  %.not2 = icmp eq i64 %2, 0, !dbg !202
  br i1 %.not2, label %._crit_edge, label %.lr.ph, !dbg !203

.lr.ph:                                           ; preds = %3
  %4 = trunc i32 %1 to i8
  br label %5, !dbg !203

5:                                                ; preds = %.lr.ph, %5
  %.04 = phi ptr [ %0, %.lr.ph ], [ %7, %5 ]
  %.013 = phi i64 [ %2, %.lr.ph ], [ %6, %5 ]
  call void @llvm.dbg.value(metadata ptr %.04, metadata !199, metadata !DIExpression()), !dbg !196
  call void @llvm.dbg.value(metadata i64 %.013, metadata !198, metadata !DIExpression()), !dbg !196
  %6 = add i64 %.013, -1, !dbg !204
  call void @llvm.dbg.value(metadata i64 %6, metadata !198, metadata !DIExpression()), !dbg !196
  %7 = getelementptr inbounds i8, ptr %.04, i64 1, !dbg !205
  call void @llvm.dbg.value(metadata ptr %7, metadata !199, metadata !DIExpression()), !dbg !196
  store i8 %4, ptr %.04, align 1, !dbg !206
  call void @llvm.dbg.value(metadata i64 %6, metadata !198, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !196
  %.not = icmp eq i64 %6, 0, !dbg !202
  br i1 %.not, label %._crit_edge, label %5, !dbg !203, !llvm.loop !207

._crit_edge:                                      ; preds = %5, %3
  ret ptr %0, !dbg !210
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #0

; Function Attrs: argmemonly mustprogress nocallback nofree nounwind willreturn writeonly
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

attributes #0 = { nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
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
!15 = distinct !DISubprogram(name: "PathIsRelativeW", scope: !16, file: !16, line: 71, type: !17, scopeLine: 71, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!16 = !DIFile(filename: "./oda_stubs.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "b280bddcdf9f538b04aebd61bf7b5b24")
!17 = !DISubroutineType(cc: DW_CC_nocall, types: !18)
!18 = !{!19, !21}
!19 = !DIDerivedType(tag: DW_TAG_typedef, name: "BOOL", file: !16, line: 22, baseType: !20)
!20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !22, size: 64)
!22 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !23)
!23 = !DIDerivedType(tag: DW_TAG_typedef, name: "WCHAR", file: !16, line: 19, baseType: !24)
!24 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!25 = !{}
!26 = !DILocalVariable(name: "path", arg: 1, scope: !15, file: !16, line: 71, type: !21)
!27 = !DILocation(line: 0, scope: !15)
!28 = !DILocalVariable(name: "ret", scope: !15, file: !16, line: 73, type: !19)
!29 = !DILocation(line: 74, column: 5, scope: !15)
!30 = !DILocation(line: 75, column: 17, scope: !15)
!31 = !DILocation(line: 75, column: 26, scope: !15)
!32 = !DILocation(line: 75, column: 5, scope: !15)
!33 = !DILocation(line: 76, column: 12, scope: !15)
!34 = !DILocation(line: 77, column: 1, scope: !15)
!35 = distinct !DISubprogram(name: "PathIsUNCW", scope: !16, file: !16, line: 87, type: !17, scopeLine: 87, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!36 = !DILocalVariable(name: "path", arg: 1, scope: !35, file: !16, line: 87, type: !21)
!37 = !DILocation(line: 0, scope: !35)
!38 = !DILocalVariable(name: "ret", scope: !35, file: !16, line: 89, type: !19)
!39 = !DILocation(line: 90, column: 5, scope: !35)
!40 = !DILocation(line: 91, column: 17, scope: !35)
!41 = !DILocation(line: 91, column: 26, scope: !35)
!42 = !DILocation(line: 91, column: 5, scope: !35)
!43 = !DILocation(line: 92, column: 12, scope: !35)
!44 = !DILocation(line: 93, column: 1, scope: !35)
!45 = distinct !DISubprogram(name: "PathStripToRootW", scope: !16, file: !16, line: 103, type: !46, scopeLine: 103, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!46 = !DISubroutineType(cc: DW_CC_nocall, types: !47)
!47 = !{!19, !48}
!48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !23, size: 64)
!49 = !DILocalVariable(name: "path", arg: 1, scope: !45, file: !16, line: 103, type: !48)
!50 = !DILocation(line: 0, scope: !45)
!51 = !DILocation(line: 104, column: 14, scope: !52)
!52 = distinct !DILexicalBlock(scope: !45, file: !16, line: 104, column: 9)
!53 = !DILocation(line: 104, column: 9, scope: !45)
!54 = !DILocalVariable(name: "ret", scope: !45, file: !16, line: 105, type: !19)
!55 = !DILocation(line: 106, column: 5, scope: !45)
!56 = !DILocation(line: 107, column: 17, scope: !45)
!57 = !DILocation(line: 107, column: 26, scope: !45)
!58 = !DILocation(line: 107, column: 5, scope: !45)
!59 = !DILocation(line: 108, column: 5, scope: !45)
!60 = !DILocation(line: 109, column: 1, scope: !45)
!61 = distinct !DISubprogram(name: "KERNELBASE_lstrlenW", scope: !16, file: !16, line: 132, type: !62, scopeLine: 132, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!62 = !DISubroutineType(types: !63)
!63 = !{!20, !64}
!64 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPCWSTR", file: !16, line: 20, baseType: !21)
!65 = !DILocalVariable(name: "str", arg: 1, scope: !61, file: !16, line: 132, type: !64)
!66 = !DILocation(line: 0, scope: !61)
!67 = !DILocation(line: 133, column: 13, scope: !68)
!68 = distinct !DILexicalBlock(scope: !61, file: !16, line: 133, column: 9)
!69 = !DILocation(line: 133, column: 9, scope: !61)
!70 = !DILocalVariable(name: "len", scope: !61, file: !16, line: 134, type: !20)
!71 = !DILocation(line: 135, column: 5, scope: !61)
!72 = !DILocation(line: 136, column: 17, scope: !61)
!73 = !DILocation(line: 136, column: 26, scope: !61)
!74 = !DILocation(line: 136, column: 5, scope: !61)
!75 = !DILocation(line: 137, column: 9, scope: !76)
!76 = distinct !DILexicalBlock(scope: !61, file: !16, line: 137, column: 9)
!77 = !DILocation(line: 137, column: 13, scope: !76)
!78 = !DILocation(line: 137, column: 9, scope: !61)
!79 = !DILocation(line: 137, column: 30, scope: !76)
!80 = !DILocation(line: 137, column: 37, scope: !76)
!81 = !DILocation(line: 137, column: 18, scope: !76)
!82 = !DILocation(line: 138, column: 12, scope: !61)
!83 = !DILocation(line: 139, column: 1, scope: !61)
!84 = distinct !DISubprogram(name: "PathCombineW", scope: !1, file: !1, line: 32, type: !85, scopeLine: 33, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!85 = !DISubroutineType(types: !86)
!86 = !{!87, !48, !21, !21}
!87 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPWSTR", file: !16, line: 21, baseType: !48)
!88 = !DILocalVariable(name: "dst", arg: 1, scope: !84, file: !1, line: 32, type: !48)
!89 = !DILocation(line: 0, scope: !84)
!90 = !DILocalVariable(name: "dir", arg: 2, scope: !84, file: !1, line: 32, type: !21)
!91 = !DILocalVariable(name: "file", arg: 3, scope: !84, file: !1, line: 32, type: !21)
!92 = !DILocalVariable(name: "use_both", scope: !84, file: !1, line: 34, type: !19)
!93 = !DILocalVariable(name: "strip", scope: !84, file: !1, line: 34, type: !19)
!94 = !DILocalVariable(name: "tmp", scope: !84, file: !1, line: 35, type: !95)
!95 = !DICompositeType(tag: DW_TAG_array_type, baseType: !23, size: 4160, elements: !96)
!96 = !{!97}
!97 = !DISubrange(count: 260)
!98 = !DILocation(line: 35, column: 11, scope: !84)
!99 = !DILocation(line: 37, column: 10, scope: !100)
!100 = distinct !DILexicalBlock(scope: !84, file: !1, line: 37, column: 9)
!101 = !DILocation(line: 37, column: 9, scope: !84)
!102 = !DILocation(line: 40, column: 10, scope: !103)
!103 = distinct !DILexicalBlock(scope: !84, file: !1, line: 40, column: 9)
!104 = !DILocation(line: 40, column: 14, scope: !103)
!105 = !DILocation(line: 42, column: 16, scope: !106)
!106 = distinct !DILexicalBlock(scope: !103, file: !1, line: 41, column: 5)
!107 = !DILocation(line: 43, column: 9, scope: !106)
!108 = !DILocation(line: 46, column: 11, scope: !109)
!109 = distinct !DILexicalBlock(scope: !84, file: !1, line: 46, column: 9)
!110 = !DILocation(line: 46, column: 16, scope: !109)
!111 = !DILocation(line: 46, column: 20, scope: !109)
!112 = !DILocation(line: 46, column: 27, scope: !109)
!113 = !DILocation(line: 50, column: 23, scope: !114)
!114 = distinct !DILexicalBlock(scope: !109, file: !1, line: 50, column: 14)
!115 = !DILocation(line: 50, column: 28, scope: !114)
!116 = !DILocation(line: 50, column: 32, scope: !114)
!117 = !DILocation(line: 50, column: 14, scope: !109)
!118 = !DILocation(line: 52, column: 22, scope: !119)
!119 = distinct !DILexicalBlock(scope: !120, file: !1, line: 52, column: 13)
!120 = distinct !DILexicalBlock(scope: !114, file: !1, line: 51, column: 5)
!121 = !DILocation(line: 52, column: 27, scope: !119)
!122 = !DILocation(line: 52, column: 30, scope: !119)
!123 = !DILocation(line: 52, column: 36, scope: !119)
!124 = !DILocation(line: 52, column: 44, scope: !119)
!125 = !DILocation(line: 52, column: 47, scope: !119)
!126 = !DILocation(line: 52, column: 13, scope: !120)
!127 = !DILocation(line: 70, column: 13, scope: !128)
!128 = distinct !DILexicalBlock(scope: !129, file: !1, line: 69, column: 9)
!129 = distinct !DILexicalBlock(scope: !130, file: !1, line: 68, column: 13)
!130 = distinct !DILexicalBlock(scope: !131, file: !1, line: 66, column: 5)
!131 = distinct !DILexicalBlock(scope: !84, file: !1, line: 65, column: 9)
!132 = !DILocation(line: 71, column: 17, scope: !128)
!133 = !DILocation(line: 72, column: 9, scope: !128)
!134 = !DILocation(line: 74, column: 14, scope: !135)
!135 = distinct !DILexicalBlock(scope: !130, file: !1, line: 74, column: 13)
!136 = !DILocation(line: 74, column: 39, scope: !135)
!137 = !DILocation(line: 74, column: 42, scope: !135)
!138 = !DILocation(line: 74, column: 69, scope: !135)
!139 = !DILocation(line: 74, column: 67, scope: !135)
!140 = !DILocation(line: 74, column: 95, scope: !135)
!141 = !DILocation(line: 74, column: 13, scope: !130)
!142 = !DILocation(line: 76, column: 20, scope: !143)
!143 = distinct !DILexicalBlock(scope: !135, file: !1, line: 75, column: 9)
!144 = !DILocation(line: 77, column: 13, scope: !143)
!145 = !DILocation(line: 80, column: 9, scope: !130)
!146 = !DILocation(line: 81, column: 5, scope: !130)
!147 = !DILocation(line: 83, column: 5, scope: !84)
!148 = !DILocation(line: 84, column: 5, scope: !84)
!149 = !DILocation(line: 85, column: 1, scope: !84)
!150 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 87, type: !151, scopeLine: 88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!151 = !DISubroutineType(types: !152)
!152 = !{!20}
!153 = !DILocalVariable(name: "dir", scope: !150, file: !1, line: 89, type: !95)
!154 = !DILocation(line: 89, column: 11, scope: !150)
!155 = !DILocalVariable(name: "file", scope: !150, file: !1, line: 90, type: !95)
!156 = !DILocation(line: 90, column: 11, scope: !150)
!157 = !DILocalVariable(name: "dst", scope: !150, file: !1, line: 91, type: !95)
!158 = !DILocation(line: 91, column: 11, scope: !150)
!159 = !DILocation(line: 93, column: 5, scope: !150)
!160 = !DILocation(line: 94, column: 5, scope: !150)
!161 = !DILocation(line: 96, column: 17, scope: !150)
!162 = !DILocation(line: 96, column: 33, scope: !150)
!163 = !DILocation(line: 96, column: 5, scope: !150)
!164 = !DILocation(line: 97, column: 17, scope: !150)
!165 = !DILocation(line: 97, column: 34, scope: !150)
!166 = !DILocation(line: 97, column: 5, scope: !150)
!167 = !DILocation(line: 103, column: 17, scope: !150)
!168 = !DILocation(line: 103, column: 29, scope: !150)
!169 = !DILocation(line: 103, column: 50, scope: !150)
!170 = !DILocation(line: 103, column: 57, scope: !150)
!171 = !DILocation(line: 103, column: 64, scope: !150)
!172 = !DILocation(line: 103, column: 74, scope: !150)
!173 = !DILocation(line: 103, column: 5, scope: !150)
!174 = !DILocation(line: 104, column: 17, scope: !150)
!175 = !DILocation(line: 104, column: 30, scope: !150)
!176 = !DILocation(line: 104, column: 52, scope: !150)
!177 = !DILocation(line: 104, column: 60, scope: !150)
!178 = !DILocation(line: 104, column: 67, scope: !150)
!179 = !DILocation(line: 104, column: 78, scope: !150)
!180 = !DILocation(line: 104, column: 5, scope: !150)
!181 = !DILocation(line: 107, column: 18, scope: !150)
!182 = !DILocalVariable(name: "out", scope: !150, file: !1, line: 107, type: !87)
!183 = !DILocation(line: 0, scope: !150)
!184 = !DILocation(line: 110, column: 42, scope: !150)
!185 = !DILocation(line: 110, column: 48, scope: !150)
!186 = !DILocation(line: 110, column: 5, scope: !150)
!187 = !DILocation(line: 112, column: 5, scope: !150)
!188 = distinct !DISubprogram(name: "memset", scope: !189, file: !189, line: 12, type: !190, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !4, retainedNodes: !25)
!189 = !DIFile(filename: "runtime/Freestanding/memset.c", directory: "/home/guren/klee", checksumkind: CSK_MD5, checksum: "f66ef9ef9131ab198e93a41b1a9ae1fc")
!190 = !DISubroutineType(types: !191)
!191 = !{!3, !3, !20, !192}
!192 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !193, line: 46, baseType: !194)
!193 = !DIFile(filename: "/usr/lib/llvm-15/lib/clang/15.0.7/include/stddef.h", directory: "", checksumkind: CSK_MD5, checksum: "b76978376d35d5cd171876ac58ac1256")
!194 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!195 = !DILocalVariable(name: "dst", arg: 1, scope: !188, file: !189, line: 12, type: !3)
!196 = !DILocation(line: 0, scope: !188)
!197 = !DILocalVariable(name: "s", arg: 2, scope: !188, file: !189, line: 12, type: !20)
!198 = !DILocalVariable(name: "count", arg: 3, scope: !188, file: !189, line: 12, type: !192)
!199 = !DILocalVariable(name: "a", scope: !188, file: !189, line: 13, type: !200)
!200 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !201, size: 64)
!201 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!202 = !DILocation(line: 14, column: 18, scope: !188)
!203 = !DILocation(line: 14, column: 3, scope: !188)
!204 = !DILocation(line: 14, column: 15, scope: !188)
!205 = !DILocation(line: 15, column: 7, scope: !188)
!206 = !DILocation(line: 15, column: 10, scope: !188)
!207 = distinct !{!207, !203, !208, !209}
!208 = !DILocation(line: 15, column: 12, scope: !188)
!209 = !{!"llvm.loop.mustprogress"}
!210 = !DILocation(line: 16, column: 3, scope: !188)
