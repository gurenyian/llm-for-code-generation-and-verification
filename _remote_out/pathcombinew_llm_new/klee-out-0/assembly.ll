; ModuleID = 'harness.bc'
source_filename = "harness_pathcombinew.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [22 x i8] c"PathCanonicalizeW_ret\00", align 1
@.str.1 = private unnamed_addr constant [20 x i8] c"PathIsRelativeW_ret\00", align 1
@.str.2 = private unnamed_addr constant [15 x i8] c"PathIsUNCW_ret\00", align 1
@.str.3 = private unnamed_addr constant [21 x i8] c"PathStripToRootW_ret\00", align 1
@.str.5 = private unnamed_addr constant [4 x i8] c"dir\00", align 1
@.str.6 = private unnamed_addr constant [5 x i8] c"file\00", align 1
@.str.7 = private unnamed_addr constant [18 x i8] c"PathCombineW_out0\00", align 1
@.str.8 = private unnamed_addr constant [24 x i8] c"myPathAddBackslashW_ret\00", align 1

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #0

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathCanonicalizeW(ptr noundef readnone %0) unnamed_addr #1 !dbg !15 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !27, metadata !DIExpression()), !dbg !28
  call void @llvm.dbg.value(metadata ptr %0, metadata !29, metadata !DIExpression()), !dbg !28
  %3 = icmp eq ptr %0, null, !dbg !30
  br i1 %3, label %11, label %4, !dbg !32

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !33, metadata !DIExpression(DW_OP_deref)), !dbg !28
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str) #5, !dbg !34
  %5 = load i32, ptr %2, align 4, !dbg !35
  call void @llvm.dbg.value(metadata i32 %5, metadata !33, metadata !DIExpression()), !dbg !28
  call void @llvm.dbg.value(metadata i32 %5, metadata !33, metadata !DIExpression()), !dbg !28
  %6 = icmp ult i32 %5, 2, !dbg !36
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !37
  %8 = load i32, ptr %2, align 4, !dbg !38
  call void @llvm.dbg.value(metadata i32 %8, metadata !33, metadata !DIExpression()), !dbg !28
  %9 = icmp eq i32 %8, 1, !dbg !39
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !40
  br label %11, !dbg !41

11:                                               ; preds = %1, %4
  ret void, !dbg !41
}

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

declare void @klee_assume(i64 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathIsRelativeW() unnamed_addr #1 !dbg !42 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !45, metadata !DIExpression()), !dbg !46
  call void @llvm.dbg.value(metadata ptr %1, metadata !47, metadata !DIExpression(DW_OP_deref)), !dbg !46
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull @.str.1) #5, !dbg !48
  %2 = load i32, ptr %1, align 4, !dbg !49
  call void @llvm.dbg.value(metadata i32 %2, metadata !47, metadata !DIExpression()), !dbg !46
  %3 = icmp ult i32 %2, 2, !dbg !50
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !51
  %5 = load i32, ptr %1, align 4, !dbg !52
  call void @llvm.dbg.value(metadata i32 %5, metadata !47, metadata !DIExpression()), !dbg !46
  %6 = icmp eq i32 %5, 1, !dbg !53
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !54
  ret void, !dbg !55
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathIsUNCW() unnamed_addr #1 !dbg !56 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !57, metadata !DIExpression()), !dbg !58
  call void @llvm.dbg.value(metadata ptr %1, metadata !59, metadata !DIExpression(DW_OP_deref)), !dbg !58
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull @.str.2) #5, !dbg !60
  %2 = load i32, ptr %1, align 4, !dbg !61
  call void @llvm.dbg.value(metadata i32 %2, metadata !59, metadata !DIExpression()), !dbg !58
  %3 = icmp ult i32 %2, 2, !dbg !62
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !63
  %5 = load i32, ptr %1, align 4, !dbg !64
  call void @llvm.dbg.value(metadata i32 %5, metadata !59, metadata !DIExpression()), !dbg !58
  %6 = icmp eq i32 %5, 1, !dbg !65
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !66
  ret void, !dbg !67
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathStripToRootW(ptr noundef readnone %0) unnamed_addr #1 !dbg !68 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !71, metadata !DIExpression()), !dbg !72
  %3 = icmp eq ptr %0, null, !dbg !73
  br i1 %3, label %11, label %4, !dbg !75

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !76, metadata !DIExpression(DW_OP_deref)), !dbg !72
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.3) #5, !dbg !77
  %5 = load i32, ptr %2, align 4, !dbg !78
  call void @llvm.dbg.value(metadata i32 %5, metadata !76, metadata !DIExpression()), !dbg !72
  call void @llvm.dbg.value(metadata i32 %5, metadata !76, metadata !DIExpression()), !dbg !72
  %6 = icmp ult i32 %5, 2, !dbg !79
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !80
  %8 = load i32, ptr %2, align 4, !dbg !81
  call void @llvm.dbg.value(metadata i32 %8, metadata !76, metadata !DIExpression()), !dbg !72
  %9 = icmp eq i32 %8, 1, !dbg !82
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !83
  br label %11, !dbg !84

11:                                               ; preds = %1, %4
  ret void, !dbg !84
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc ptr @PathCombineW(ptr noundef writeonly %0, ptr noundef readonly %1, ptr noundef readonly %2) unnamed_addr #1 !dbg !85 {
  %4 = alloca [260 x i16], align 16
  call void @llvm.dbg.value(metadata ptr %0, metadata !89, metadata !DIExpression()), !dbg !90
  call void @llvm.dbg.value(metadata ptr %1, metadata !91, metadata !DIExpression()), !dbg !90
  call void @llvm.dbg.value(metadata ptr %2, metadata !92, metadata !DIExpression()), !dbg !90
  call void @llvm.dbg.value(metadata i32 0, metadata !93, metadata !DIExpression()), !dbg !90
  call void @llvm.dbg.value(metadata i32 0, metadata !94, metadata !DIExpression()), !dbg !90
  call void @llvm.dbg.declare(metadata ptr %4, metadata !95, metadata !DIExpression()), !dbg !99
  %.not = icmp eq ptr %0, null, !dbg !100
  br i1 %.not, label %19, label %5, !dbg !102

5:                                                ; preds = %3
  %6 = icmp ne ptr %1, null, !dbg !103
  %7 = icmp ne ptr %2, null
  %or.cond = or i1 %6, %7, !dbg !105
  br i1 %or.cond, label %9, label %8, !dbg !105

8:                                                ; preds = %5
  store i16 0, ptr %0, align 2, !dbg !106
  br label %19, !dbg !108

9:                                                ; preds = %5
  %.not7 = icmp eq ptr %2, null, !dbg !109
  br i1 %.not7, label %.thread22, label %10, !dbg !111

10:                                               ; preds = %9
  %11 = load i16, ptr %2, align 2, !dbg !112
  %12 = icmp eq i16 %11, 0, !dbg !112
  %cond20 = icmp eq ptr %1, null
  %or.cond27 = or i1 %cond20, %12, !dbg !113
  br i1 %or.cond27, label %.thread22, label %13, !dbg !113

13:                                               ; preds = %10
  %14 = load i16, ptr %1, align 2, !dbg !114
  %.not16 = icmp eq i16 %14, 0, !dbg !114
  br i1 %.not16, label %.thread22, label %15, !dbg !116

15:                                               ; preds = %13
  tail call fastcc void @PathIsRelativeW(), !dbg !117
  %.pr = load i16, ptr %1, align 2, !dbg !118
  %.not13 = icmp eq i16 %.pr, 0, !dbg !118
  br i1 %.not13, label %.thread22, label %16, !dbg !121

16:                                               ; preds = %15
  %17 = load i16, ptr %2, align 2, !dbg !122
  %.not14 = icmp eq i16 %17, 92, !dbg !123
  br i1 %.not14, label %18, label %.thread22, !dbg !124

18:                                               ; preds = %16
  tail call fastcc void @PathIsUNCW(), !dbg !125
  call void @llvm.dbg.value(metadata i32 undef, metadata !94, metadata !DIExpression()), !dbg !90
  call void @llvm.dbg.value(metadata i32 undef, metadata !93, metadata !DIExpression()), !dbg !90
  call fastcc void @PathStripToRootW(ptr noundef nonnull %4), !dbg !126
  call void @llvm.dbg.value(metadata ptr %2, metadata !92, metadata !DIExpression(DW_OP_plus_uconst, 2, DW_OP_stack_value)), !dbg !90
  call fastcc void @myPathAddBackslashW(ptr noundef nonnull %4), !dbg !131
  store i16 0, ptr %0, align 2, !dbg !133
  br label %19, !dbg !135

.thread22:                                        ; preds = %9, %15, %16, %13, %10
  call fastcc void @PathCanonicalizeW(ptr noundef nonnull %4), !dbg !136
  br label %19, !dbg !137

19:                                               ; preds = %3, %.thread22, %18, %8
  %.0 = phi ptr [ null, %18 ], [ %0, %.thread22 ], [ null, %8 ], [ null, %3 ], !dbg !90
  ret ptr %.0, !dbg !138
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @myPathAddBackslashW(ptr noundef readnone %0) unnamed_addr #1 !dbg !139 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !142, metadata !DIExpression()), !dbg !143
  %3 = icmp eq ptr %0, null, !dbg !144
  br i1 %3, label %11, label %4, !dbg !146

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !147, metadata !DIExpression(DW_OP_deref)), !dbg !143
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.8) #5, !dbg !148
  %5 = load i32, ptr %2, align 4, !dbg !149
  call void @llvm.dbg.value(metadata i32 %5, metadata !147, metadata !DIExpression()), !dbg !143
  call void @llvm.dbg.value(metadata i32 %5, metadata !147, metadata !DIExpression()), !dbg !143
  %6 = icmp ult i32 %5, 2, !dbg !150
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !151
  %8 = load i32, ptr %2, align 4, !dbg !152
  call void @llvm.dbg.value(metadata i32 %8, metadata !147, metadata !DIExpression()), !dbg !143
  %9 = icmp eq i32 %8, 1, !dbg !153
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !154
  br label %11, !dbg !155

11:                                               ; preds = %1, %4
  ret void, !dbg !155
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !156 {
  %1 = alloca [260 x i16], align 16
  %2 = alloca [260 x i16], align 16
  %3 = alloca [260 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !159, metadata !DIExpression()), !dbg !160
  %4 = call ptr @memset(ptr %1, i32 0, i64 520), !dbg !160
  call void @llvm.dbg.declare(metadata ptr %2, metadata !161, metadata !DIExpression()), !dbg !162
  %5 = call ptr @memset(ptr %2, i32 0, i64 520), !dbg !162
  call void @llvm.dbg.declare(metadata ptr %3, metadata !163, metadata !DIExpression()), !dbg !164
  %6 = call ptr @memset(ptr %3, i32 0, i64 520), !dbg !164
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 520, ptr noundef nonnull @.str.5) #5, !dbg !165
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 520, ptr noundef nonnull @.str.6) #5, !dbg !166
  %7 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 259, !dbg !167
  %8 = load i16, ptr %7, align 2, !dbg !167
  %9 = icmp eq i16 %8, 0, !dbg !168
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !169
  %11 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 259, !dbg !170
  %12 = load i16, ptr %11, align 2, !dbg !170
  %13 = icmp eq i16 %12, 0, !dbg !171
  %14 = zext i1 %13 to i64
  call void @klee_assume(i64 noundef %14) #5, !dbg !172
  %15 = load i16, ptr %1, align 16, !dbg !173
  switch i16 %15, label %16 [
    i16 92, label %22
    i16 0, label %22
  ], !dbg !174

16:                                               ; preds = %0
  %17 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 1, !dbg !175
  %18 = load i16, ptr %17, align 2, !dbg !175
  %19 = icmp eq i16 %18, 58, !dbg !176
  br i1 %19, label %22, label %20, !dbg !177

20:                                               ; preds = %16
  %21 = icmp ugt i16 %15, 64, !dbg !178
  %phi.cast1 = zext i1 %21 to i64, !dbg !177
  br label %22, !dbg !177

22:                                               ; preds = %0, %0, %20, %16
  %23 = phi i64 [ 1, %16 ], [ 1, %0 ], [ %phi.cast1, %20 ], [ 1, %0 ]
  call void @klee_assume(i64 noundef %23) #5, !dbg !179
  %24 = load i16, ptr %2, align 16, !dbg !180
  switch i16 %24, label %25 [
    i16 92, label %31
    i16 0, label %31
  ], !dbg !181

25:                                               ; preds = %22
  %26 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 1, !dbg !182
  %27 = load i16, ptr %26, align 2, !dbg !182
  %28 = icmp eq i16 %27, 58, !dbg !183
  br i1 %28, label %31, label %29, !dbg !184

29:                                               ; preds = %25
  %30 = icmp ugt i16 %24, 64, !dbg !185
  %phi.cast2 = zext i1 %30 to i64, !dbg !184
  br label %31, !dbg !184

31:                                               ; preds = %22, %22, %29, %25
  %32 = phi i64 [ 1, %25 ], [ 1, %22 ], [ %phi.cast2, %29 ], [ 1, %22 ]
  call void @klee_assume(i64 noundef %32) #5, !dbg !186
  %33 = call fastcc ptr @PathCombineW(ptr noundef nonnull %3, ptr noundef nonnull %1, ptr noundef nonnull %2), !dbg !187
  call void @llvm.dbg.value(metadata ptr %33, metadata !188, metadata !DIExpression()), !dbg !189
  %.not = icmp eq ptr %33, null, !dbg !190
  br i1 %.not, label %37, label %34, !dbg !190

34:                                               ; preds = %31
  %35 = load i16, ptr %33, align 2, !dbg !191
  %36 = zext i16 %35 to i32, !dbg !191
  br label %37, !dbg !190

37:                                               ; preds = %31, %34
  %38 = phi i32 [ %36, %34 ], [ 0, %31 ], !dbg !190
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.7, i32 noundef %38) #5, !dbg !192
  ret i32 0, !dbg !193
}

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind writeonly uwtable
define dso_local ptr @memset(ptr noundef returned writeonly %0, i32 noundef %1, i64 noundef %2) local_unnamed_addr #3 !dbg !194 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !201, metadata !DIExpression()), !dbg !202
  call void @llvm.dbg.value(metadata i32 %1, metadata !203, metadata !DIExpression()), !dbg !202
  call void @llvm.dbg.value(metadata i64 %2, metadata !204, metadata !DIExpression()), !dbg !202
  call void @llvm.dbg.value(metadata ptr %0, metadata !205, metadata !DIExpression()), !dbg !202
  call void @llvm.dbg.value(metadata i64 %2, metadata !204, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !202
  %.not2 = icmp eq i64 %2, 0, !dbg !208
  br i1 %.not2, label %._crit_edge, label %.lr.ph, !dbg !209

.lr.ph:                                           ; preds = %3
  %4 = trunc i32 %1 to i8
  br label %5, !dbg !209

5:                                                ; preds = %.lr.ph, %5
  %.04 = phi ptr [ %0, %.lr.ph ], [ %7, %5 ]
  %.013 = phi i64 [ %2, %.lr.ph ], [ %6, %5 ]
  call void @llvm.dbg.value(metadata ptr %.04, metadata !205, metadata !DIExpression()), !dbg !202
  call void @llvm.dbg.value(metadata i64 %.013, metadata !204, metadata !DIExpression()), !dbg !202
  %6 = add i64 %.013, -1, !dbg !210
  call void @llvm.dbg.value(metadata i64 %6, metadata !204, metadata !DIExpression()), !dbg !202
  %7 = getelementptr inbounds i8, ptr %.04, i64 1, !dbg !211
  call void @llvm.dbg.value(metadata ptr %7, metadata !205, metadata !DIExpression()), !dbg !202
  store i8 %4, ptr %.04, align 1, !dbg !212
  call void @llvm.dbg.value(metadata i64 %6, metadata !204, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !202
  %.not = icmp eq i64 %6, 0, !dbg !208
  br i1 %.not, label %._crit_edge, label %5, !dbg !209, !llvm.loop !213

._crit_edge:                                      ; preds = %5, %3
  ret ptr %0, !dbg !216
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
!16 = !DIFile(filename: "./oda_stubs.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "d9866bae28e56398afb431fbe2bb7f5d")
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
!30 = !DILocation(line: 66, column: 14, scope: !31)
!31 = distinct !DILexicalBlock(scope: !15, file: !16, line: 66, column: 9)
!32 = !DILocation(line: 66, column: 9, scope: !15)
!33 = !DILocalVariable(name: "ret", scope: !15, file: !16, line: 67, type: !19)
!34 = !DILocation(line: 68, column: 5, scope: !15)
!35 = !DILocation(line: 69, column: 17, scope: !15)
!36 = !DILocation(line: 69, column: 29, scope: !15)
!37 = !DILocation(line: 69, column: 5, scope: !15)
!38 = !DILocation(line: 70, column: 17, scope: !15)
!39 = !DILocation(line: 70, column: 21, scope: !15)
!40 = !DILocation(line: 70, column: 5, scope: !15)
!41 = !DILocation(line: 71, column: 1, scope: !15)
!42 = distinct !DISubprogram(name: "PathIsRelativeW", scope: !16, file: !16, line: 81, type: !43, scopeLine: 81, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!43 = !DISubroutineType(cc: DW_CC_nocall, types: !44)
!44 = !{!19, !24}
!45 = !DILocalVariable(name: "path", arg: 1, scope: !42, file: !16, line: 81, type: !24)
!46 = !DILocation(line: 0, scope: !42)
!47 = !DILocalVariable(name: "ret", scope: !42, file: !16, line: 83, type: !19)
!48 = !DILocation(line: 84, column: 5, scope: !42)
!49 = !DILocation(line: 85, column: 17, scope: !42)
!50 = !DILocation(line: 85, column: 29, scope: !42)
!51 = !DILocation(line: 85, column: 5, scope: !42)
!52 = !DILocation(line: 86, column: 17, scope: !42)
!53 = !DILocation(line: 86, column: 21, scope: !42)
!54 = !DILocation(line: 86, column: 5, scope: !42)
!55 = !DILocation(line: 87, column: 1, scope: !42)
!56 = distinct !DISubprogram(name: "PathIsUNCW", scope: !16, file: !16, line: 97, type: !43, scopeLine: 97, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!57 = !DILocalVariable(name: "path", arg: 1, scope: !56, file: !16, line: 97, type: !24)
!58 = !DILocation(line: 0, scope: !56)
!59 = !DILocalVariable(name: "ret", scope: !56, file: !16, line: 99, type: !19)
!60 = !DILocation(line: 100, column: 5, scope: !56)
!61 = !DILocation(line: 101, column: 17, scope: !56)
!62 = !DILocation(line: 101, column: 29, scope: !56)
!63 = !DILocation(line: 101, column: 5, scope: !56)
!64 = !DILocation(line: 102, column: 17, scope: !56)
!65 = !DILocation(line: 102, column: 21, scope: !56)
!66 = !DILocation(line: 102, column: 5, scope: !56)
!67 = !DILocation(line: 103, column: 1, scope: !56)
!68 = distinct !DISubprogram(name: "PathStripToRootW", scope: !16, file: !16, line: 113, type: !69, scopeLine: 113, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!69 = !DISubroutineType(cc: DW_CC_nocall, types: !70)
!70 = !{!19, !21}
!71 = !DILocalVariable(name: "path", arg: 1, scope: !68, file: !16, line: 113, type: !21)
!72 = !DILocation(line: 0, scope: !68)
!73 = !DILocation(line: 114, column: 14, scope: !74)
!74 = distinct !DILexicalBlock(scope: !68, file: !16, line: 114, column: 9)
!75 = !DILocation(line: 114, column: 9, scope: !68)
!76 = !DILocalVariable(name: "ret", scope: !68, file: !16, line: 115, type: !19)
!77 = !DILocation(line: 116, column: 5, scope: !68)
!78 = !DILocation(line: 117, column: 17, scope: !68)
!79 = !DILocation(line: 117, column: 29, scope: !68)
!80 = !DILocation(line: 117, column: 5, scope: !68)
!81 = !DILocation(line: 118, column: 17, scope: !68)
!82 = !DILocation(line: 118, column: 21, scope: !68)
!83 = !DILocation(line: 118, column: 5, scope: !68)
!84 = !DILocation(line: 119, column: 1, scope: !68)
!85 = distinct !DISubprogram(name: "PathCombineW", scope: !1, file: !1, line: 32, type: !86, scopeLine: 33, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!86 = !DISubroutineType(types: !87)
!87 = !{!88, !21, !24, !24}
!88 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPWSTR", file: !16, line: 21, baseType: !21)
!89 = !DILocalVariable(name: "dst", arg: 1, scope: !85, file: !1, line: 32, type: !21)
!90 = !DILocation(line: 0, scope: !85)
!91 = !DILocalVariable(name: "dir", arg: 2, scope: !85, file: !1, line: 32, type: !24)
!92 = !DILocalVariable(name: "file", arg: 3, scope: !85, file: !1, line: 32, type: !24)
!93 = !DILocalVariable(name: "use_both", scope: !85, file: !1, line: 34, type: !19)
!94 = !DILocalVariable(name: "strip", scope: !85, file: !1, line: 34, type: !19)
!95 = !DILocalVariable(name: "tmp", scope: !85, file: !1, line: 35, type: !96)
!96 = !DICompositeType(tag: DW_TAG_array_type, baseType: !22, size: 4160, elements: !97)
!97 = !{!98}
!98 = !DISubrange(count: 260)
!99 = !DILocation(line: 35, column: 11, scope: !85)
!100 = !DILocation(line: 37, column: 10, scope: !101)
!101 = distinct !DILexicalBlock(scope: !85, file: !1, line: 37, column: 9)
!102 = !DILocation(line: 37, column: 9, scope: !85)
!103 = !DILocation(line: 40, column: 10, scope: !104)
!104 = distinct !DILexicalBlock(scope: !85, file: !1, line: 40, column: 9)
!105 = !DILocation(line: 40, column: 14, scope: !104)
!106 = !DILocation(line: 42, column: 16, scope: !107)
!107 = distinct !DILexicalBlock(scope: !104, file: !1, line: 41, column: 5)
!108 = !DILocation(line: 43, column: 9, scope: !107)
!109 = !DILocation(line: 46, column: 11, scope: !110)
!110 = distinct !DILexicalBlock(scope: !85, file: !1, line: 46, column: 9)
!111 = !DILocation(line: 46, column: 16, scope: !110)
!112 = !DILocation(line: 46, column: 20, scope: !110)
!113 = !DILocation(line: 46, column: 27, scope: !110)
!114 = !DILocation(line: 50, column: 23, scope: !115)
!115 = distinct !DILexicalBlock(scope: !110, file: !1, line: 50, column: 14)
!116 = !DILocation(line: 50, column: 28, scope: !115)
!117 = !DILocation(line: 50, column: 32, scope: !115)
!118 = !DILocation(line: 52, column: 22, scope: !119)
!119 = distinct !DILexicalBlock(scope: !120, file: !1, line: 52, column: 13)
!120 = distinct !DILexicalBlock(scope: !115, file: !1, line: 51, column: 5)
!121 = !DILocation(line: 52, column: 27, scope: !119)
!122 = !DILocation(line: 52, column: 30, scope: !119)
!123 = !DILocation(line: 52, column: 36, scope: !119)
!124 = !DILocation(line: 52, column: 44, scope: !119)
!125 = !DILocation(line: 52, column: 47, scope: !119)
!126 = !DILocation(line: 70, column: 13, scope: !127)
!127 = distinct !DILexicalBlock(scope: !128, file: !1, line: 69, column: 9)
!128 = distinct !DILexicalBlock(scope: !129, file: !1, line: 68, column: 13)
!129 = distinct !DILexicalBlock(scope: !130, file: !1, line: 66, column: 5)
!130 = distinct !DILexicalBlock(scope: !85, file: !1, line: 65, column: 9)
!131 = !DILocation(line: 74, column: 14, scope: !132)
!132 = distinct !DILexicalBlock(scope: !129, file: !1, line: 74, column: 13)
!133 = !DILocation(line: 76, column: 20, scope: !134)
!134 = distinct !DILexicalBlock(scope: !132, file: !1, line: 75, column: 9)
!135 = !DILocation(line: 77, column: 13, scope: !134)
!136 = !DILocation(line: 83, column: 5, scope: !85)
!137 = !DILocation(line: 84, column: 5, scope: !85)
!138 = !DILocation(line: 85, column: 1, scope: !85)
!139 = distinct !DISubprogram(name: "myPathAddBackslashW", scope: !16, file: !16, line: 49, type: !140, scopeLine: 49, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !0, retainedNodes: !26)
!140 = !DISubroutineType(cc: DW_CC_nocall, types: !141)
!141 = !{!88, !88}
!142 = !DILocalVariable(name: "lpszPath", arg: 1, scope: !139, file: !16, line: 49, type: !88)
!143 = !DILocation(line: 0, scope: !139)
!144 = !DILocation(line: 50, column: 18, scope: !145)
!145 = distinct !DILexicalBlock(scope: !139, file: !16, line: 50, column: 9)
!146 = !DILocation(line: 50, column: 9, scope: !139)
!147 = !DILocalVariable(name: "ret", scope: !139, file: !16, line: 51, type: !19)
!148 = !DILocation(line: 52, column: 5, scope: !139)
!149 = !DILocation(line: 53, column: 17, scope: !139)
!150 = !DILocation(line: 53, column: 29, scope: !139)
!151 = !DILocation(line: 53, column: 5, scope: !139)
!152 = !DILocation(line: 54, column: 17, scope: !139)
!153 = !DILocation(line: 54, column: 21, scope: !139)
!154 = !DILocation(line: 54, column: 5, scope: !139)
!155 = !DILocation(line: 55, column: 1, scope: !139)
!156 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 87, type: !157, scopeLine: 88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!157 = !DISubroutineType(types: !158)
!158 = !{!20}
!159 = !DILocalVariable(name: "dir", scope: !156, file: !1, line: 89, type: !96)
!160 = !DILocation(line: 89, column: 11, scope: !156)
!161 = !DILocalVariable(name: "file", scope: !156, file: !1, line: 90, type: !96)
!162 = !DILocation(line: 90, column: 11, scope: !156)
!163 = !DILocalVariable(name: "dst", scope: !156, file: !1, line: 91, type: !96)
!164 = !DILocation(line: 91, column: 11, scope: !156)
!165 = !DILocation(line: 93, column: 5, scope: !156)
!166 = !DILocation(line: 94, column: 5, scope: !156)
!167 = !DILocation(line: 96, column: 17, scope: !156)
!168 = !DILocation(line: 96, column: 33, scope: !156)
!169 = !DILocation(line: 96, column: 5, scope: !156)
!170 = !DILocation(line: 97, column: 17, scope: !156)
!171 = !DILocation(line: 97, column: 34, scope: !156)
!172 = !DILocation(line: 97, column: 5, scope: !156)
!173 = !DILocation(line: 103, column: 17, scope: !156)
!174 = !DILocation(line: 103, column: 29, scope: !156)
!175 = !DILocation(line: 103, column: 50, scope: !156)
!176 = !DILocation(line: 103, column: 57, scope: !156)
!177 = !DILocation(line: 103, column: 64, scope: !156)
!178 = !DILocation(line: 103, column: 74, scope: !156)
!179 = !DILocation(line: 103, column: 5, scope: !156)
!180 = !DILocation(line: 104, column: 17, scope: !156)
!181 = !DILocation(line: 104, column: 30, scope: !156)
!182 = !DILocation(line: 104, column: 52, scope: !156)
!183 = !DILocation(line: 104, column: 60, scope: !156)
!184 = !DILocation(line: 104, column: 67, scope: !156)
!185 = !DILocation(line: 104, column: 78, scope: !156)
!186 = !DILocation(line: 104, column: 5, scope: !156)
!187 = !DILocation(line: 107, column: 18, scope: !156)
!188 = !DILocalVariable(name: "out", scope: !156, file: !1, line: 107, type: !88)
!189 = !DILocation(line: 0, scope: !156)
!190 = !DILocation(line: 110, column: 42, scope: !156)
!191 = !DILocation(line: 110, column: 48, scope: !156)
!192 = !DILocation(line: 110, column: 5, scope: !156)
!193 = !DILocation(line: 112, column: 5, scope: !156)
!194 = distinct !DISubprogram(name: "memset", scope: !195, file: !195, line: 12, type: !196, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !4, retainedNodes: !26)
!195 = !DIFile(filename: "runtime/Freestanding/memset.c", directory: "/home/guren/klee", checksumkind: CSK_MD5, checksum: "f66ef9ef9131ab198e93a41b1a9ae1fc")
!196 = !DISubroutineType(types: !197)
!197 = !{!3, !3, !20, !198}
!198 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !199, line: 46, baseType: !200)
!199 = !DIFile(filename: "/usr/lib/llvm-15/lib/clang/15.0.7/include/stddef.h", directory: "", checksumkind: CSK_MD5, checksum: "b76978376d35d5cd171876ac58ac1256")
!200 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!201 = !DILocalVariable(name: "dst", arg: 1, scope: !194, file: !195, line: 12, type: !3)
!202 = !DILocation(line: 0, scope: !194)
!203 = !DILocalVariable(name: "s", arg: 2, scope: !194, file: !195, line: 12, type: !20)
!204 = !DILocalVariable(name: "count", arg: 3, scope: !194, file: !195, line: 12, type: !198)
!205 = !DILocalVariable(name: "a", scope: !194, file: !195, line: 13, type: !206)
!206 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !207, size: 64)
!207 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!208 = !DILocation(line: 14, column: 18, scope: !194)
!209 = !DILocation(line: 14, column: 3, scope: !194)
!210 = !DILocation(line: 14, column: 15, scope: !194)
!211 = !DILocation(line: 15, column: 7, scope: !194)
!212 = !DILocation(line: 15, column: 10, scope: !194)
!213 = distinct !{!213, !209, !214, !215}
!214 = !DILocation(line: 15, column: 12, scope: !194)
!215 = !{!"llvm.loop.mustprogress"}
!216 = !DILocation(line: 16, column: 3, scope: !194)
