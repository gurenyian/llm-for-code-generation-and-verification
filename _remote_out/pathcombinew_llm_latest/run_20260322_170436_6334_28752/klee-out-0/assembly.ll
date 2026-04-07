; ModuleID = 'harness.bc'
source_filename = "harness_pathcombinew.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str.2 = private unnamed_addr constant [20 x i8] c"PathIsRelativeW_ret\00", align 1
@.str.3 = private unnamed_addr constant [15 x i8] c"PathIsUNCW_ret\00", align 1
@.str.4 = private unnamed_addr constant [21 x i8] c"PathStripToRootW_ret\00", align 1
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
define internal fastcc ptr @PathCombineW(ptr noundef writeonly %0, ptr noundef readonly %1, ptr noundef readonly %2) unnamed_addr #2 !dbg !61 {
  %4 = alloca [260 x i16], align 16
  call void @llvm.dbg.value(metadata ptr %0, metadata !65, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata ptr %1, metadata !67, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata ptr %2, metadata !68, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata i32 0, metadata !69, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata i32 0, metadata !70, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.declare(metadata ptr %4, metadata !71, metadata !DIExpression()), !dbg !75
  %.not = icmp eq ptr %0, null, !dbg !76
  br i1 %.not, label %.thread22, label %5, !dbg !78

5:                                                ; preds = %3
  %6 = icmp ne ptr %1, null, !dbg !79
  %7 = icmp ne ptr %2, null
  %or.cond = or i1 %6, %7, !dbg !81
  br i1 %or.cond, label %9, label %8, !dbg !81

8:                                                ; preds = %5
  store i16 0, ptr %0, align 2, !dbg !82
  br label %.thread22, !dbg !84

9:                                                ; preds = %5
  %.not7 = icmp eq ptr %2, null, !dbg !85
  br i1 %.not7, label %.thread22, label %10, !dbg !87

10:                                               ; preds = %9
  %11 = load i16, ptr %2, align 2, !dbg !88
  %12 = icmp eq i16 %11, 0, !dbg !88
  %cond20 = icmp eq ptr %1, null
  %or.cond27 = or i1 %cond20, %12, !dbg !89
  br i1 %or.cond27, label %.thread22, label %13, !dbg !89

13:                                               ; preds = %10
  %14 = load i16, ptr %1, align 2, !dbg !90
  %.not16 = icmp eq i16 %14, 0, !dbg !90
  br i1 %.not16, label %.thread22, label %15, !dbg !92

15:                                               ; preds = %13
  %16 = tail call fastcc i32 @PathIsRelativeW(), !dbg !93
  %.not17 = icmp eq i32 %16, 0, !dbg !93
  br i1 %.not17, label %17, label %.thread25, !dbg !94

17:                                               ; preds = %15
  %.pr = load i16, ptr %1, align 2, !dbg !95
  %.not13 = icmp eq i16 %.pr, 0, !dbg !95
  br i1 %.not13, label %.thread22, label %18, !dbg !98

18:                                               ; preds = %17
  %19 = load i16, ptr %2, align 2, !dbg !99
  %.not14 = icmp eq i16 %19, 92, !dbg !100
  br i1 %.not14, label %20, label %.thread22, !dbg !101

20:                                               ; preds = %18
  %21 = tail call fastcc i32 @PathIsUNCW(), !dbg !102
  %.not15 = icmp eq i32 %21, 0, !dbg !102
  br i1 %.not15, label %22, label %.thread22, !dbg !103

22:                                               ; preds = %20
  call void @llvm.dbg.value(metadata i32 undef, metadata !70, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata i32 undef, metadata !69, metadata !DIExpression()), !dbg !66
  call fastcc void @PathStripToRootW(ptr noundef nonnull %4), !dbg !104
  call void @llvm.dbg.value(metadata ptr %2, metadata !68, metadata !DIExpression(DW_OP_plus_uconst, 2, DW_OP_stack_value)), !dbg !66
  br label %.thread25, !dbg !109

.thread25:                                        ; preds = %22, %15
  call void @llvm.dbg.value(metadata ptr undef, metadata !68, metadata !DIExpression()), !dbg !66
  store i16 0, ptr %0, align 2, !dbg !110
  br label %.thread22, !dbg !113

.thread22:                                        ; preds = %9, %17, %18, %20, %13, %10, %3, %.thread25, %8
  %.0 = phi ptr [ null, %.thread25 ], [ null, %8 ], [ null, %3 ], [ %0, %10 ], [ %0, %13 ], [ %0, %20 ], [ %0, %18 ], [ %0, %17 ], [ %0, %9 ], !dbg !66
  ret ptr %.0, !dbg !114
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #2 !dbg !115 {
  %1 = alloca [260 x i16], align 16
  %2 = alloca [260 x i16], align 16
  %3 = alloca [260 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !118, metadata !DIExpression()), !dbg !119
  %4 = call ptr @memset(ptr %1, i32 0, i64 520), !dbg !119
  call void @llvm.dbg.declare(metadata ptr %2, metadata !120, metadata !DIExpression()), !dbg !121
  %5 = call ptr @memset(ptr %2, i32 0, i64 520), !dbg !121
  call void @llvm.dbg.declare(metadata ptr %3, metadata !122, metadata !DIExpression()), !dbg !123
  %6 = call ptr @memset(ptr %3, i32 0, i64 520), !dbg !123
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 520, ptr noundef nonnull @.str.6) #5, !dbg !124
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 520, ptr noundef nonnull @.str.7) #5, !dbg !125
  %7 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 259, !dbg !126
  %8 = load i16, ptr %7, align 2, !dbg !126
  %9 = icmp eq i16 %8, 0, !dbg !127
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !128
  %11 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 259, !dbg !129
  %12 = load i16, ptr %11, align 2, !dbg !129
  %13 = icmp eq i16 %12, 0, !dbg !130
  %14 = zext i1 %13 to i64
  call void @klee_assume(i64 noundef %14) #5, !dbg !131
  %15 = load i16, ptr %1, align 16, !dbg !132
  switch i16 %15, label %16 [
    i16 92, label %22
    i16 0, label %22
  ], !dbg !133

16:                                               ; preds = %0
  %17 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 1, !dbg !134
  %18 = load i16, ptr %17, align 2, !dbg !134
  %19 = icmp eq i16 %18, 58, !dbg !135
  br i1 %19, label %22, label %20, !dbg !136

20:                                               ; preds = %16
  %21 = icmp ugt i16 %15, 64, !dbg !137
  %phi.cast1 = zext i1 %21 to i64, !dbg !136
  br label %22, !dbg !136

22:                                               ; preds = %0, %0, %20, %16
  %23 = phi i64 [ 1, %16 ], [ 1, %0 ], [ %phi.cast1, %20 ], [ 1, %0 ]
  call void @klee_assume(i64 noundef %23) #5, !dbg !138
  %24 = load i16, ptr %2, align 16, !dbg !139
  switch i16 %24, label %25 [
    i16 92, label %31
    i16 0, label %31
  ], !dbg !140

25:                                               ; preds = %22
  %26 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 1, !dbg !141
  %27 = load i16, ptr %26, align 2, !dbg !141
  %28 = icmp eq i16 %27, 58, !dbg !142
  br i1 %28, label %31, label %29, !dbg !143

29:                                               ; preds = %25
  %30 = icmp ugt i16 %24, 64, !dbg !144
  %phi.cast2 = zext i1 %30 to i64, !dbg !143
  br label %31, !dbg !143

31:                                               ; preds = %22, %22, %29, %25
  %32 = phi i64 [ 1, %25 ], [ 1, %22 ], [ %phi.cast2, %29 ], [ 1, %22 ]
  call void @klee_assume(i64 noundef %32) #5, !dbg !145
  %33 = call fastcc ptr @PathCombineW(ptr noundef nonnull %3, ptr noundef nonnull %1, ptr noundef nonnull %2), !dbg !146
  call void @llvm.dbg.value(metadata ptr %33, metadata !147, metadata !DIExpression()), !dbg !148
  %.not = icmp eq ptr %33, null, !dbg !149
  br i1 %.not, label %37, label %34, !dbg !149

34:                                               ; preds = %31
  %35 = load i16, ptr %33, align 2, !dbg !150
  %36 = zext i16 %35 to i32, !dbg !150
  br label %37, !dbg !149

37:                                               ; preds = %31, %34
  %38 = phi i32 [ %36, %34 ], [ 0, %31 ], !dbg !149
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.8, i32 noundef %38) #5, !dbg !151
  ret i32 0, !dbg !152
}

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #1

; Function Attrs: nofree noinline norecurse nosync nounwind writeonly uwtable
define dso_local ptr @memset(ptr noundef returned writeonly %0, i32 noundef %1, i64 noundef %2) local_unnamed_addr #3 !dbg !153 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !160, metadata !DIExpression()), !dbg !161
  call void @llvm.dbg.value(metadata i32 %1, metadata !162, metadata !DIExpression()), !dbg !161
  call void @llvm.dbg.value(metadata i64 %2, metadata !163, metadata !DIExpression()), !dbg !161
  call void @llvm.dbg.value(metadata ptr %0, metadata !164, metadata !DIExpression()), !dbg !161
  call void @llvm.dbg.value(metadata i64 %2, metadata !163, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !161
  %.not2 = icmp eq i64 %2, 0, !dbg !167
  br i1 %.not2, label %._crit_edge, label %.lr.ph, !dbg !168

.lr.ph:                                           ; preds = %3
  %4 = trunc i32 %1 to i8
  br label %5, !dbg !168

5:                                                ; preds = %.lr.ph, %5
  %.04 = phi ptr [ %0, %.lr.ph ], [ %7, %5 ]
  %.013 = phi i64 [ %2, %.lr.ph ], [ %6, %5 ]
  call void @llvm.dbg.value(metadata ptr %.04, metadata !164, metadata !DIExpression()), !dbg !161
  call void @llvm.dbg.value(metadata i64 %.013, metadata !163, metadata !DIExpression()), !dbg !161
  %6 = add i64 %.013, -1, !dbg !169
  call void @llvm.dbg.value(metadata i64 %6, metadata !163, metadata !DIExpression()), !dbg !161
  %7 = getelementptr inbounds i8, ptr %.04, i64 1, !dbg !170
  call void @llvm.dbg.value(metadata ptr %7, metadata !164, metadata !DIExpression()), !dbg !161
  store i8 %4, ptr %.04, align 1, !dbg !171
  call void @llvm.dbg.value(metadata i64 %6, metadata !163, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !161
  %.not = icmp eq i64 %6, 0, !dbg !167
  br i1 %.not, label %._crit_edge, label %5, !dbg !168, !llvm.loop !172

._crit_edge:                                      ; preds = %5, %3
  ret ptr %0, !dbg !175
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
!15 = distinct !DISubprogram(name: "PathIsRelativeW", scope: !16, file: !16, line: 72, type: !17, scopeLine: 72, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!16 = !DIFile(filename: "./oda_stubs.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "182908e2d71cacf211400649642d51c4")
!17 = !DISubroutineType(cc: DW_CC_nocall, types: !18)
!18 = !{!19, !21}
!19 = !DIDerivedType(tag: DW_TAG_typedef, name: "BOOL", file: !16, line: 23, baseType: !20)
!20 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !22, size: 64)
!22 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !23)
!23 = !DIDerivedType(tag: DW_TAG_typedef, name: "WCHAR", file: !16, line: 20, baseType: !24)
!24 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!25 = !{}
!26 = !DILocalVariable(name: "path", arg: 1, scope: !15, file: !16, line: 72, type: !21)
!27 = !DILocation(line: 0, scope: !15)
!28 = !DILocalVariable(name: "ret", scope: !15, file: !16, line: 74, type: !19)
!29 = !DILocation(line: 75, column: 5, scope: !15)
!30 = !DILocation(line: 76, column: 17, scope: !15)
!31 = !DILocation(line: 76, column: 26, scope: !15)
!32 = !DILocation(line: 76, column: 5, scope: !15)
!33 = !DILocation(line: 77, column: 12, scope: !15)
!34 = !DILocation(line: 78, column: 1, scope: !15)
!35 = distinct !DISubprogram(name: "PathIsUNCW", scope: !16, file: !16, line: 88, type: !17, scopeLine: 88, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!36 = !DILocalVariable(name: "path", arg: 1, scope: !35, file: !16, line: 88, type: !21)
!37 = !DILocation(line: 0, scope: !35)
!38 = !DILocalVariable(name: "ret", scope: !35, file: !16, line: 90, type: !19)
!39 = !DILocation(line: 91, column: 5, scope: !35)
!40 = !DILocation(line: 92, column: 17, scope: !35)
!41 = !DILocation(line: 92, column: 26, scope: !35)
!42 = !DILocation(line: 92, column: 5, scope: !35)
!43 = !DILocation(line: 93, column: 12, scope: !35)
!44 = !DILocation(line: 94, column: 1, scope: !35)
!45 = distinct !DISubprogram(name: "PathStripToRootW", scope: !16, file: !16, line: 104, type: !46, scopeLine: 104, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!46 = !DISubroutineType(cc: DW_CC_nocall, types: !47)
!47 = !{!19, !48}
!48 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !23, size: 64)
!49 = !DILocalVariable(name: "path", arg: 1, scope: !45, file: !16, line: 104, type: !48)
!50 = !DILocation(line: 0, scope: !45)
!51 = !DILocation(line: 105, column: 14, scope: !52)
!52 = distinct !DILexicalBlock(scope: !45, file: !16, line: 105, column: 9)
!53 = !DILocation(line: 105, column: 9, scope: !45)
!54 = !DILocalVariable(name: "ret", scope: !45, file: !16, line: 106, type: !19)
!55 = !DILocation(line: 107, column: 5, scope: !45)
!56 = !DILocation(line: 108, column: 17, scope: !45)
!57 = !DILocation(line: 108, column: 26, scope: !45)
!58 = !DILocation(line: 108, column: 5, scope: !45)
!59 = !DILocation(line: 109, column: 5, scope: !45)
!60 = !DILocation(line: 110, column: 1, scope: !45)
!61 = distinct !DISubprogram(name: "PathCombineW", scope: !1, file: !1, line: 32, type: !62, scopeLine: 33, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!62 = !DISubroutineType(types: !63)
!63 = !{!64, !48, !21, !21}
!64 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPWSTR", file: !16, line: 22, baseType: !48)
!65 = !DILocalVariable(name: "dst", arg: 1, scope: !61, file: !1, line: 32, type: !48)
!66 = !DILocation(line: 0, scope: !61)
!67 = !DILocalVariable(name: "dir", arg: 2, scope: !61, file: !1, line: 32, type: !21)
!68 = !DILocalVariable(name: "file", arg: 3, scope: !61, file: !1, line: 32, type: !21)
!69 = !DILocalVariable(name: "use_both", scope: !61, file: !1, line: 34, type: !19)
!70 = !DILocalVariable(name: "strip", scope: !61, file: !1, line: 34, type: !19)
!71 = !DILocalVariable(name: "tmp", scope: !61, file: !1, line: 35, type: !72)
!72 = !DICompositeType(tag: DW_TAG_array_type, baseType: !23, size: 4160, elements: !73)
!73 = !{!74}
!74 = !DISubrange(count: 260)
!75 = !DILocation(line: 35, column: 11, scope: !61)
!76 = !DILocation(line: 37, column: 10, scope: !77)
!77 = distinct !DILexicalBlock(scope: !61, file: !1, line: 37, column: 9)
!78 = !DILocation(line: 37, column: 9, scope: !61)
!79 = !DILocation(line: 40, column: 10, scope: !80)
!80 = distinct !DILexicalBlock(scope: !61, file: !1, line: 40, column: 9)
!81 = !DILocation(line: 40, column: 14, scope: !80)
!82 = !DILocation(line: 42, column: 16, scope: !83)
!83 = distinct !DILexicalBlock(scope: !80, file: !1, line: 41, column: 5)
!84 = !DILocation(line: 43, column: 9, scope: !83)
!85 = !DILocation(line: 46, column: 11, scope: !86)
!86 = distinct !DILexicalBlock(scope: !61, file: !1, line: 46, column: 9)
!87 = !DILocation(line: 46, column: 16, scope: !86)
!88 = !DILocation(line: 46, column: 20, scope: !86)
!89 = !DILocation(line: 46, column: 27, scope: !86)
!90 = !DILocation(line: 50, column: 23, scope: !91)
!91 = distinct !DILexicalBlock(scope: !86, file: !1, line: 50, column: 14)
!92 = !DILocation(line: 50, column: 28, scope: !91)
!93 = !DILocation(line: 50, column: 32, scope: !91)
!94 = !DILocation(line: 50, column: 14, scope: !86)
!95 = !DILocation(line: 52, column: 22, scope: !96)
!96 = distinct !DILexicalBlock(scope: !97, file: !1, line: 52, column: 13)
!97 = distinct !DILexicalBlock(scope: !91, file: !1, line: 51, column: 5)
!98 = !DILocation(line: 52, column: 27, scope: !96)
!99 = !DILocation(line: 52, column: 30, scope: !96)
!100 = !DILocation(line: 52, column: 36, scope: !96)
!101 = !DILocation(line: 52, column: 44, scope: !96)
!102 = !DILocation(line: 52, column: 47, scope: !96)
!103 = !DILocation(line: 52, column: 13, scope: !97)
!104 = !DILocation(line: 70, column: 13, scope: !105)
!105 = distinct !DILexicalBlock(scope: !106, file: !1, line: 69, column: 9)
!106 = distinct !DILexicalBlock(scope: !107, file: !1, line: 68, column: 13)
!107 = distinct !DILexicalBlock(scope: !108, file: !1, line: 66, column: 5)
!108 = distinct !DILexicalBlock(scope: !61, file: !1, line: 65, column: 9)
!109 = !DILocation(line: 72, column: 9, scope: !105)
!110 = !DILocation(line: 76, column: 20, scope: !111)
!111 = distinct !DILexicalBlock(scope: !112, file: !1, line: 75, column: 9)
!112 = distinct !DILexicalBlock(scope: !107, file: !1, line: 74, column: 13)
!113 = !DILocation(line: 77, column: 13, scope: !111)
!114 = !DILocation(line: 85, column: 1, scope: !61)
!115 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 87, type: !116, scopeLine: 88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !25)
!116 = !DISubroutineType(types: !117)
!117 = !{!20}
!118 = !DILocalVariable(name: "dir", scope: !115, file: !1, line: 89, type: !72)
!119 = !DILocation(line: 89, column: 11, scope: !115)
!120 = !DILocalVariable(name: "file", scope: !115, file: !1, line: 90, type: !72)
!121 = !DILocation(line: 90, column: 11, scope: !115)
!122 = !DILocalVariable(name: "dst", scope: !115, file: !1, line: 91, type: !72)
!123 = !DILocation(line: 91, column: 11, scope: !115)
!124 = !DILocation(line: 93, column: 5, scope: !115)
!125 = !DILocation(line: 94, column: 5, scope: !115)
!126 = !DILocation(line: 96, column: 17, scope: !115)
!127 = !DILocation(line: 96, column: 33, scope: !115)
!128 = !DILocation(line: 96, column: 5, scope: !115)
!129 = !DILocation(line: 97, column: 17, scope: !115)
!130 = !DILocation(line: 97, column: 34, scope: !115)
!131 = !DILocation(line: 97, column: 5, scope: !115)
!132 = !DILocation(line: 103, column: 17, scope: !115)
!133 = !DILocation(line: 103, column: 29, scope: !115)
!134 = !DILocation(line: 103, column: 50, scope: !115)
!135 = !DILocation(line: 103, column: 57, scope: !115)
!136 = !DILocation(line: 103, column: 64, scope: !115)
!137 = !DILocation(line: 103, column: 74, scope: !115)
!138 = !DILocation(line: 103, column: 5, scope: !115)
!139 = !DILocation(line: 104, column: 17, scope: !115)
!140 = !DILocation(line: 104, column: 30, scope: !115)
!141 = !DILocation(line: 104, column: 52, scope: !115)
!142 = !DILocation(line: 104, column: 60, scope: !115)
!143 = !DILocation(line: 104, column: 67, scope: !115)
!144 = !DILocation(line: 104, column: 78, scope: !115)
!145 = !DILocation(line: 104, column: 5, scope: !115)
!146 = !DILocation(line: 107, column: 18, scope: !115)
!147 = !DILocalVariable(name: "out", scope: !115, file: !1, line: 107, type: !64)
!148 = !DILocation(line: 0, scope: !115)
!149 = !DILocation(line: 110, column: 42, scope: !115)
!150 = !DILocation(line: 110, column: 48, scope: !115)
!151 = !DILocation(line: 110, column: 5, scope: !115)
!152 = !DILocation(line: 112, column: 5, scope: !115)
!153 = distinct !DISubprogram(name: "memset", scope: !154, file: !154, line: 12, type: !155, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !4, retainedNodes: !25)
!154 = !DIFile(filename: "runtime/Freestanding/memset.c", directory: "/home/guren/klee", checksumkind: CSK_MD5, checksum: "f66ef9ef9131ab198e93a41b1a9ae1fc")
!155 = !DISubroutineType(types: !156)
!156 = !{!3, !3, !20, !157}
!157 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !158, line: 46, baseType: !159)
!158 = !DIFile(filename: "/usr/lib/llvm-15/lib/clang/15.0.7/include/stddef.h", directory: "", checksumkind: CSK_MD5, checksum: "b76978376d35d5cd171876ac58ac1256")
!159 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!160 = !DILocalVariable(name: "dst", arg: 1, scope: !153, file: !154, line: 12, type: !3)
!161 = !DILocation(line: 0, scope: !153)
!162 = !DILocalVariable(name: "s", arg: 2, scope: !153, file: !154, line: 12, type: !20)
!163 = !DILocalVariable(name: "count", arg: 3, scope: !153, file: !154, line: 12, type: !157)
!164 = !DILocalVariable(name: "a", scope: !153, file: !154, line: 13, type: !165)
!165 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !166, size: 64)
!166 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!167 = !DILocation(line: 14, column: 18, scope: !153)
!168 = !DILocation(line: 14, column: 3, scope: !153)
!169 = !DILocation(line: 14, column: 15, scope: !153)
!170 = !DILocation(line: 15, column: 7, scope: !153)
!171 = !DILocation(line: 15, column: 10, scope: !153)
!172 = distinct !{!172, !168, !173, !174}
!173 = !DILocation(line: 15, column: 12, scope: !153)
!174 = !{!"llvm.loop.mustprogress"}
!175 = !DILocation(line: 16, column: 3, scope: !153)
