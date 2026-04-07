; ModuleID = 'harness.bc'
source_filename = "harness_pathcombinew.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"dir\00", align 1
@.str.1 = private unnamed_addr constant [5 x i8] c"file\00", align 1
@.str.2 = private unnamed_addr constant [18 x i8] c"PathCombineW_out0\00", align 1

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #0

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathCanonicalizeW(ptr noundef readnone %0) unnamed_addr #1 !dbg !15 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !27, metadata !DIExpression()), !dbg !28
  call void @llvm.dbg.value(metadata ptr %0, metadata !29, metadata !DIExpression()), !dbg !28
  call void @llvm.dbg.value(metadata ptr %2, metadata !30, metadata !DIExpression(DW_OP_deref)), !dbg !28
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull inttoptr (i64 1601332596 to ptr)) #5, !dbg !31
  %3 = load i32, ptr %2, align 4, !dbg !32
  call void @llvm.dbg.value(metadata i32 %3, metadata !30, metadata !DIExpression()), !dbg !28
  %4 = icmp ult i32 %3, 2, !dbg !33
  %5 = zext i1 %4 to i64
  call void @klee_assume(i64 noundef %5) #5, !dbg !34
  %6 = load i32, ptr %2, align 4, !dbg !35
  call void @llvm.dbg.value(metadata i32 %6, metadata !30, metadata !DIExpression()), !dbg !28
  %.not = icmp eq i32 %6, 0, !dbg !35
  br i1 %.not, label %10, label %7, !dbg !37

7:                                                ; preds = %1
  %8 = icmp ne ptr %0, null, !dbg !38
  %9 = zext i1 %8 to i64
  call void @klee_assume(i64 noundef %9) #5, !dbg !39
  br label %10, !dbg !39

10:                                               ; preds = %7, %1
  ret void, !dbg !40
}

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

declare void @klee_assume(i64 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathIsRelativeW() unnamed_addr #1 !dbg !41 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !44, metadata !DIExpression()), !dbg !45
  call void @llvm.dbg.value(metadata ptr %1, metadata !46, metadata !DIExpression(DW_OP_deref)), !dbg !45
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull inttoptr (i64 1601332596 to ptr)) #5, !dbg !47
  %2 = load i32, ptr %1, align 4, !dbg !48
  call void @llvm.dbg.value(metadata i32 %2, metadata !46, metadata !DIExpression()), !dbg !45
  %3 = icmp ult i32 %2, 2, !dbg !49
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !50
  ret void, !dbg !51
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathIsUNCW() unnamed_addr #1 !dbg !52 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !53, metadata !DIExpression()), !dbg !54
  call void @llvm.dbg.value(metadata ptr %1, metadata !55, metadata !DIExpression(DW_OP_deref)), !dbg !54
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull inttoptr (i64 1601332596 to ptr)) #5, !dbg !56
  %2 = load i32, ptr %1, align 4, !dbg !57
  call void @llvm.dbg.value(metadata i32 %2, metadata !55, metadata !DIExpression()), !dbg !54
  %3 = icmp ult i32 %2, 2, !dbg !58
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #5, !dbg !59
  ret void, !dbg !60
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathStripToRootW(ptr noundef readnone %0) unnamed_addr #1 !dbg !61 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !64, metadata !DIExpression()), !dbg !65
  %3 = icmp eq ptr %0, null, !dbg !66
  br i1 %3, label %8, label %4, !dbg !68

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !69, metadata !DIExpression(DW_OP_deref)), !dbg !65
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull inttoptr (i64 1601332596 to ptr)) #5, !dbg !70
  %5 = load i32, ptr %2, align 4, !dbg !71
  call void @llvm.dbg.value(metadata i32 %5, metadata !69, metadata !DIExpression()), !dbg !65
  call void @llvm.dbg.value(metadata i32 %5, metadata !69, metadata !DIExpression()), !dbg !65
  %6 = icmp ult i32 %5, 2, !dbg !72
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !73
  br label %8, !dbg !74

8:                                                ; preds = %1, %4
  ret void, !dbg !74
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc ptr @PathCombineW(ptr noundef writeonly %0, ptr noundef readonly %1, ptr noundef readonly %2) unnamed_addr #1 !dbg !75 {
  %4 = alloca [260 x i16], align 16
  call void @llvm.dbg.value(metadata ptr %0, metadata !79, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.value(metadata ptr %1, metadata !81, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.value(metadata ptr %2, metadata !82, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.value(metadata i32 0, metadata !83, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.value(metadata i32 0, metadata !84, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.declare(metadata ptr %4, metadata !85, metadata !DIExpression()), !dbg !89
  %.not = icmp eq ptr %0, null, !dbg !90
  br i1 %.not, label %19, label %5, !dbg !92

5:                                                ; preds = %3
  %6 = icmp ne ptr %1, null, !dbg !93
  %7 = icmp ne ptr %2, null
  %or.cond = or i1 %6, %7, !dbg !95
  br i1 %or.cond, label %9, label %8, !dbg !95

8:                                                ; preds = %5
  store i16 0, ptr %0, align 2, !dbg !96
  br label %19, !dbg !98

9:                                                ; preds = %5
  %.not7 = icmp eq ptr %2, null, !dbg !99
  br i1 %.not7, label %.thread22, label %10, !dbg !101

10:                                               ; preds = %9
  %11 = load i16, ptr %2, align 2, !dbg !102
  %12 = icmp eq i16 %11, 0, !dbg !102
  %cond20 = icmp eq ptr %1, null
  %or.cond27 = or i1 %cond20, %12, !dbg !103
  br i1 %or.cond27, label %.thread22, label %13, !dbg !103

13:                                               ; preds = %10
  %14 = load i16, ptr %1, align 2, !dbg !104
  %.not16 = icmp eq i16 %14, 0, !dbg !104
  br i1 %.not16, label %.thread22, label %15, !dbg !106

15:                                               ; preds = %13
  tail call fastcc void @PathIsRelativeW(), !dbg !107
  %.pr = load i16, ptr %1, align 2, !dbg !108
  %.not13 = icmp eq i16 %.pr, 0, !dbg !108
  br i1 %.not13, label %.thread22, label %16, !dbg !111

16:                                               ; preds = %15
  %17 = load i16, ptr %2, align 2, !dbg !112
  %.not14 = icmp eq i16 %17, 92, !dbg !113
  br i1 %.not14, label %18, label %.thread22, !dbg !114

18:                                               ; preds = %16
  tail call fastcc void @PathIsUNCW(), !dbg !115
  call void @llvm.dbg.value(metadata i32 undef, metadata !84, metadata !DIExpression()), !dbg !80
  call void @llvm.dbg.value(metadata i32 undef, metadata !83, metadata !DIExpression()), !dbg !80
  call fastcc void @PathStripToRootW(ptr noundef nonnull %4), !dbg !116
  call void @llvm.dbg.value(metadata ptr %2, metadata !82, metadata !DIExpression(DW_OP_plus_uconst, 2, DW_OP_stack_value)), !dbg !80
  store i16 0, ptr %0, align 2, !dbg !121
  br label %19, !dbg !124

.thread22:                                        ; preds = %9, %15, %16, %13, %10
  call fastcc void @PathCanonicalizeW(ptr noundef nonnull %4), !dbg !125
  br label %19, !dbg !126

19:                                               ; preds = %3, %.thread22, %18, %8
  %.0 = phi ptr [ null, %18 ], [ %0, %.thread22 ], [ null, %8 ], [ null, %3 ], !dbg !80
  ret ptr %.0, !dbg !127
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !128 {
  %1 = alloca [260 x i16], align 16
  %2 = alloca [260 x i16], align 16
  %3 = alloca [260 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !131, metadata !DIExpression()), !dbg !132
  %4 = call ptr @memset(ptr %1, i32 0, i64 520), !dbg !132
  call void @llvm.dbg.declare(metadata ptr %2, metadata !133, metadata !DIExpression()), !dbg !134
  %5 = call ptr @memset(ptr %2, i32 0, i64 520), !dbg !134
  call void @llvm.dbg.declare(metadata ptr %3, metadata !135, metadata !DIExpression()), !dbg !136
  %6 = call ptr @memset(ptr %3, i32 0, i64 520), !dbg !136
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 520, ptr noundef nonnull @.str) #5, !dbg !137
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 520, ptr noundef nonnull @.str.1) #5, !dbg !138
  %7 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 259, !dbg !139
  %8 = load i16, ptr %7, align 2, !dbg !139
  %9 = icmp eq i16 %8, 0, !dbg !140
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #5, !dbg !141
  %11 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 259, !dbg !142
  %12 = load i16, ptr %11, align 2, !dbg !142
  %13 = icmp eq i16 %12, 0, !dbg !143
  %14 = zext i1 %13 to i64
  call void @klee_assume(i64 noundef %14) #5, !dbg !144
  %15 = load i16, ptr %1, align 16, !dbg !145
  switch i16 %15, label %16 [
    i16 92, label %22
    i16 0, label %22
  ], !dbg !146

16:                                               ; preds = %0
  %17 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 1, !dbg !147
  %18 = load i16, ptr %17, align 2, !dbg !147
  %19 = icmp eq i16 %18, 58, !dbg !148
  br i1 %19, label %22, label %20, !dbg !149

20:                                               ; preds = %16
  %21 = icmp ugt i16 %15, 64, !dbg !150
  %phi.cast1 = zext i1 %21 to i64, !dbg !149
  br label %22, !dbg !149

22:                                               ; preds = %0, %0, %20, %16
  %23 = phi i64 [ 1, %16 ], [ 1, %0 ], [ %phi.cast1, %20 ], [ 1, %0 ]
  call void @klee_assume(i64 noundef %23) #5, !dbg !151
  %24 = load i16, ptr %2, align 16, !dbg !152
  switch i16 %24, label %25 [
    i16 92, label %31
    i16 0, label %31
  ], !dbg !153

25:                                               ; preds = %22
  %26 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 1, !dbg !154
  %27 = load i16, ptr %26, align 2, !dbg !154
  %28 = icmp eq i16 %27, 58, !dbg !155
  br i1 %28, label %31, label %29, !dbg !156

29:                                               ; preds = %25
  %30 = icmp ugt i16 %24, 64, !dbg !157
  %phi.cast2 = zext i1 %30 to i64, !dbg !156
  br label %31, !dbg !156

31:                                               ; preds = %22, %22, %29, %25
  %32 = phi i64 [ 1, %25 ], [ 1, %22 ], [ %phi.cast2, %29 ], [ 1, %22 ]
  call void @klee_assume(i64 noundef %32) #5, !dbg !158
  %33 = call fastcc ptr @PathCombineW(ptr noundef nonnull %3, ptr noundef nonnull %1, ptr noundef nonnull %2), !dbg !159
  call void @llvm.dbg.value(metadata ptr %33, metadata !160, metadata !DIExpression()), !dbg !161
  %.not = icmp eq ptr %33, null, !dbg !162
  br i1 %.not, label %37, label %34, !dbg !162

34:                                               ; preds = %31
  %35 = load i16, ptr %33, align 2, !dbg !163
  %36 = zext i16 %35 to i32, !dbg !163
  br label %37, !dbg !162

37:                                               ; preds = %31, %34
  %38 = phi i32 [ %36, %34 ], [ 0, %31 ], !dbg !162
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.2, i32 noundef %38) #5, !dbg !164
  ret i32 0, !dbg !165
}

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind writeonly uwtable
define dso_local ptr @memset(ptr noundef returned writeonly %0, i32 noundef %1, i64 noundef %2) local_unnamed_addr #3 !dbg !166 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !173, metadata !DIExpression()), !dbg !174
  call void @llvm.dbg.value(metadata i32 %1, metadata !175, metadata !DIExpression()), !dbg !174
  call void @llvm.dbg.value(metadata i64 %2, metadata !176, metadata !DIExpression()), !dbg !174
  call void @llvm.dbg.value(metadata ptr %0, metadata !177, metadata !DIExpression()), !dbg !174
  call void @llvm.dbg.value(metadata i64 %2, metadata !176, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !174
  %.not2 = icmp eq i64 %2, 0, !dbg !180
  br i1 %.not2, label %._crit_edge, label %.lr.ph, !dbg !181

.lr.ph:                                           ; preds = %3
  %4 = trunc i32 %1 to i8
  br label %5, !dbg !181

5:                                                ; preds = %.lr.ph, %5
  %.04 = phi ptr [ %0, %.lr.ph ], [ %7, %5 ]
  %.013 = phi i64 [ %2, %.lr.ph ], [ %6, %5 ]
  call void @llvm.dbg.value(metadata ptr %.04, metadata !177, metadata !DIExpression()), !dbg !174
  call void @llvm.dbg.value(metadata i64 %.013, metadata !176, metadata !DIExpression()), !dbg !174
  %6 = add i64 %.013, -1, !dbg !182
  call void @llvm.dbg.value(metadata i64 %6, metadata !176, metadata !DIExpression()), !dbg !174
  %7 = getelementptr inbounds i8, ptr %.04, i64 1, !dbg !183
  call void @llvm.dbg.value(metadata ptr %7, metadata !177, metadata !DIExpression()), !dbg !174
  store i8 %4, ptr %.04, align 1, !dbg !184
  call void @llvm.dbg.value(metadata i64 %6, metadata !176, metadata !DIExpression(DW_OP_constu, 1, DW_OP_minus, DW_OP_stack_value)), !dbg !174
  %.not = icmp eq i64 %6, 0, !dbg !180
  br i1 %.not, label %._crit_edge, label %5, !dbg !181, !llvm.loop !185

._crit_edge:                                      ; preds = %5, %3
  ret ptr %0, !dbg !188
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
!15 = distinct !DISubprogram(name: "PathCanonicalizeW", scope: !16, file: !16, line: 61, type: !17, scopeLine: 61, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!16 = !DIFile(filename: "./oda_stubs.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "0b9dadb5199ab0e99cef8dbc27f2d7fd")
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
!27 = !DILocalVariable(name: "buffer", arg: 1, scope: !15, file: !16, line: 61, type: !21)
!28 = !DILocation(line: 0, scope: !15)
!29 = !DILocalVariable(name: "path", arg: 2, scope: !15, file: !16, line: 61, type: !24)
!30 = !DILocalVariable(name: "ret", scope: !15, file: !16, line: 63, type: !19)
!31 = !DILocation(line: 64, column: 5, scope: !15)
!32 = !DILocation(line: 65, column: 17, scope: !15)
!33 = !DILocation(line: 65, column: 29, scope: !15)
!34 = !DILocation(line: 65, column: 5, scope: !15)
!35 = !DILocation(line: 66, column: 9, scope: !36)
!36 = distinct !DILexicalBlock(scope: !15, file: !16, line: 66, column: 9)
!37 = !DILocation(line: 66, column: 9, scope: !15)
!38 = !DILocation(line: 66, column: 31, scope: !36)
!39 = !DILocation(line: 66, column: 14, scope: !36)
!40 = !DILocation(line: 67, column: 1, scope: !15)
!41 = distinct !DISubprogram(name: "PathIsRelativeW", scope: !16, file: !16, line: 77, type: !42, scopeLine: 77, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!42 = !DISubroutineType(cc: DW_CC_nocall, types: !43)
!43 = !{!19, !24}
!44 = !DILocalVariable(name: "path", arg: 1, scope: !41, file: !16, line: 77, type: !24)
!45 = !DILocation(line: 0, scope: !41)
!46 = !DILocalVariable(name: "ret", scope: !41, file: !16, line: 79, type: !19)
!47 = !DILocation(line: 80, column: 5, scope: !41)
!48 = !DILocation(line: 81, column: 17, scope: !41)
!49 = !DILocation(line: 81, column: 29, scope: !41)
!50 = !DILocation(line: 81, column: 5, scope: !41)
!51 = !DILocation(line: 82, column: 1, scope: !41)
!52 = distinct !DISubprogram(name: "PathIsUNCW", scope: !16, file: !16, line: 92, type: !42, scopeLine: 92, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!53 = !DILocalVariable(name: "path", arg: 1, scope: !52, file: !16, line: 92, type: !24)
!54 = !DILocation(line: 0, scope: !52)
!55 = !DILocalVariable(name: "ret", scope: !52, file: !16, line: 94, type: !19)
!56 = !DILocation(line: 95, column: 5, scope: !52)
!57 = !DILocation(line: 96, column: 17, scope: !52)
!58 = !DILocation(line: 96, column: 29, scope: !52)
!59 = !DILocation(line: 96, column: 5, scope: !52)
!60 = !DILocation(line: 97, column: 1, scope: !52)
!61 = distinct !DISubprogram(name: "PathStripToRootW", scope: !16, file: !16, line: 107, type: !62, scopeLine: 107, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!62 = !DISubroutineType(cc: DW_CC_nocall, types: !63)
!63 = !{!19, !21}
!64 = !DILocalVariable(name: "path", arg: 1, scope: !61, file: !16, line: 107, type: !21)
!65 = !DILocation(line: 0, scope: !61)
!66 = !DILocation(line: 108, column: 14, scope: !67)
!67 = distinct !DILexicalBlock(scope: !61, file: !16, line: 108, column: 9)
!68 = !DILocation(line: 108, column: 9, scope: !61)
!69 = !DILocalVariable(name: "ret", scope: !61, file: !16, line: 109, type: !19)
!70 = !DILocation(line: 110, column: 5, scope: !61)
!71 = !DILocation(line: 111, column: 17, scope: !61)
!72 = !DILocation(line: 111, column: 29, scope: !61)
!73 = !DILocation(line: 111, column: 5, scope: !61)
!74 = !DILocation(line: 112, column: 1, scope: !61)
!75 = distinct !DISubprogram(name: "PathCombineW", scope: !1, file: !1, line: 32, type: !76, scopeLine: 33, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!76 = !DISubroutineType(types: !77)
!77 = !{!78, !21, !24, !24}
!78 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPWSTR", file: !16, line: 21, baseType: !21)
!79 = !DILocalVariable(name: "dst", arg: 1, scope: !75, file: !1, line: 32, type: !21)
!80 = !DILocation(line: 0, scope: !75)
!81 = !DILocalVariable(name: "dir", arg: 2, scope: !75, file: !1, line: 32, type: !24)
!82 = !DILocalVariable(name: "file", arg: 3, scope: !75, file: !1, line: 32, type: !24)
!83 = !DILocalVariable(name: "use_both", scope: !75, file: !1, line: 34, type: !19)
!84 = !DILocalVariable(name: "strip", scope: !75, file: !1, line: 34, type: !19)
!85 = !DILocalVariable(name: "tmp", scope: !75, file: !1, line: 35, type: !86)
!86 = !DICompositeType(tag: DW_TAG_array_type, baseType: !22, size: 4160, elements: !87)
!87 = !{!88}
!88 = !DISubrange(count: 260)
!89 = !DILocation(line: 35, column: 11, scope: !75)
!90 = !DILocation(line: 37, column: 10, scope: !91)
!91 = distinct !DILexicalBlock(scope: !75, file: !1, line: 37, column: 9)
!92 = !DILocation(line: 37, column: 9, scope: !75)
!93 = !DILocation(line: 40, column: 10, scope: !94)
!94 = distinct !DILexicalBlock(scope: !75, file: !1, line: 40, column: 9)
!95 = !DILocation(line: 40, column: 14, scope: !94)
!96 = !DILocation(line: 42, column: 16, scope: !97)
!97 = distinct !DILexicalBlock(scope: !94, file: !1, line: 41, column: 5)
!98 = !DILocation(line: 43, column: 9, scope: !97)
!99 = !DILocation(line: 46, column: 11, scope: !100)
!100 = distinct !DILexicalBlock(scope: !75, file: !1, line: 46, column: 9)
!101 = !DILocation(line: 46, column: 16, scope: !100)
!102 = !DILocation(line: 46, column: 20, scope: !100)
!103 = !DILocation(line: 46, column: 27, scope: !100)
!104 = !DILocation(line: 50, column: 23, scope: !105)
!105 = distinct !DILexicalBlock(scope: !100, file: !1, line: 50, column: 14)
!106 = !DILocation(line: 50, column: 28, scope: !105)
!107 = !DILocation(line: 50, column: 32, scope: !105)
!108 = !DILocation(line: 52, column: 22, scope: !109)
!109 = distinct !DILexicalBlock(scope: !110, file: !1, line: 52, column: 13)
!110 = distinct !DILexicalBlock(scope: !105, file: !1, line: 51, column: 5)
!111 = !DILocation(line: 52, column: 27, scope: !109)
!112 = !DILocation(line: 52, column: 30, scope: !109)
!113 = !DILocation(line: 52, column: 36, scope: !109)
!114 = !DILocation(line: 52, column: 44, scope: !109)
!115 = !DILocation(line: 52, column: 47, scope: !109)
!116 = !DILocation(line: 70, column: 13, scope: !117)
!117 = distinct !DILexicalBlock(scope: !118, file: !1, line: 69, column: 9)
!118 = distinct !DILexicalBlock(scope: !119, file: !1, line: 68, column: 13)
!119 = distinct !DILexicalBlock(scope: !120, file: !1, line: 66, column: 5)
!120 = distinct !DILexicalBlock(scope: !75, file: !1, line: 65, column: 9)
!121 = !DILocation(line: 76, column: 20, scope: !122)
!122 = distinct !DILexicalBlock(scope: !123, file: !1, line: 75, column: 9)
!123 = distinct !DILexicalBlock(scope: !119, file: !1, line: 74, column: 13)
!124 = !DILocation(line: 77, column: 13, scope: !122)
!125 = !DILocation(line: 83, column: 5, scope: !75)
!126 = !DILocation(line: 84, column: 5, scope: !75)
!127 = !DILocation(line: 85, column: 1, scope: !75)
!128 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 87, type: !129, scopeLine: 88, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !26)
!129 = !DISubroutineType(types: !130)
!130 = !{!20}
!131 = !DILocalVariable(name: "dir", scope: !128, file: !1, line: 89, type: !86)
!132 = !DILocation(line: 89, column: 11, scope: !128)
!133 = !DILocalVariable(name: "file", scope: !128, file: !1, line: 90, type: !86)
!134 = !DILocation(line: 90, column: 11, scope: !128)
!135 = !DILocalVariable(name: "dst", scope: !128, file: !1, line: 91, type: !86)
!136 = !DILocation(line: 91, column: 11, scope: !128)
!137 = !DILocation(line: 93, column: 5, scope: !128)
!138 = !DILocation(line: 94, column: 5, scope: !128)
!139 = !DILocation(line: 96, column: 17, scope: !128)
!140 = !DILocation(line: 96, column: 33, scope: !128)
!141 = !DILocation(line: 96, column: 5, scope: !128)
!142 = !DILocation(line: 97, column: 17, scope: !128)
!143 = !DILocation(line: 97, column: 34, scope: !128)
!144 = !DILocation(line: 97, column: 5, scope: !128)
!145 = !DILocation(line: 103, column: 17, scope: !128)
!146 = !DILocation(line: 103, column: 29, scope: !128)
!147 = !DILocation(line: 103, column: 50, scope: !128)
!148 = !DILocation(line: 103, column: 57, scope: !128)
!149 = !DILocation(line: 103, column: 64, scope: !128)
!150 = !DILocation(line: 103, column: 74, scope: !128)
!151 = !DILocation(line: 103, column: 5, scope: !128)
!152 = !DILocation(line: 104, column: 17, scope: !128)
!153 = !DILocation(line: 104, column: 30, scope: !128)
!154 = !DILocation(line: 104, column: 52, scope: !128)
!155 = !DILocation(line: 104, column: 60, scope: !128)
!156 = !DILocation(line: 104, column: 67, scope: !128)
!157 = !DILocation(line: 104, column: 78, scope: !128)
!158 = !DILocation(line: 104, column: 5, scope: !128)
!159 = !DILocation(line: 107, column: 18, scope: !128)
!160 = !DILocalVariable(name: "out", scope: !128, file: !1, line: 107, type: !78)
!161 = !DILocation(line: 0, scope: !128)
!162 = !DILocation(line: 110, column: 42, scope: !128)
!163 = !DILocation(line: 110, column: 48, scope: !128)
!164 = !DILocation(line: 110, column: 5, scope: !128)
!165 = !DILocation(line: 112, column: 5, scope: !128)
!166 = distinct !DISubprogram(name: "memset", scope: !167, file: !167, line: 12, type: !168, scopeLine: 12, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !4, retainedNodes: !26)
!167 = !DIFile(filename: "runtime/Freestanding/memset.c", directory: "/home/guren/klee", checksumkind: CSK_MD5, checksum: "f66ef9ef9131ab198e93a41b1a9ae1fc")
!168 = !DISubroutineType(types: !169)
!169 = !{!3, !3, !20, !170}
!170 = !DIDerivedType(tag: DW_TAG_typedef, name: "size_t", file: !171, line: 46, baseType: !172)
!171 = !DIFile(filename: "/usr/lib/llvm-15/lib/clang/15.0.7/include/stddef.h", directory: "", checksumkind: CSK_MD5, checksum: "b76978376d35d5cd171876ac58ac1256")
!172 = !DIBasicType(name: "unsigned long", size: 64, encoding: DW_ATE_unsigned)
!173 = !DILocalVariable(name: "dst", arg: 1, scope: !166, file: !167, line: 12, type: !3)
!174 = !DILocation(line: 0, scope: !166)
!175 = !DILocalVariable(name: "s", arg: 2, scope: !166, file: !167, line: 12, type: !20)
!176 = !DILocalVariable(name: "count", arg: 3, scope: !166, file: !167, line: 12, type: !170)
!177 = !DILocalVariable(name: "a", scope: !166, file: !167, line: 13, type: !178)
!178 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !179, size: 64)
!179 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!180 = !DILocation(line: 14, column: 18, scope: !166)
!181 = !DILocation(line: 14, column: 3, scope: !166)
!182 = !DILocation(line: 14, column: 15, scope: !166)
!183 = !DILocation(line: 15, column: 7, scope: !166)
!184 = !DILocation(line: 15, column: 10, scope: !166)
!185 = distinct !{!185, !181, !186, !187}
!186 = !DILocation(line: 15, column: 12, scope: !166)
!187 = !{!"llvm.loop.mustprogress"}
!188 = !DILocation(line: 16, column: 3, scope: !166)
