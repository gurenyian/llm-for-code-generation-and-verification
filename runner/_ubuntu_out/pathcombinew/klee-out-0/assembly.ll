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
define internal fastcc void @PathCanonicalizeW(ptr noundef readnone %0) unnamed_addr #1 !dbg !12 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !24, metadata !DIExpression()), !dbg !25
  call void @llvm.dbg.value(metadata ptr %0, metadata !26, metadata !DIExpression()), !dbg !25
  %3 = icmp eq ptr %0, null, !dbg !27
  br i1 %3, label %8, label %4, !dbg !29

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !30, metadata !DIExpression(DW_OP_deref)), !dbg !25
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str) #3, !dbg !31
  %5 = load i32, ptr %2, align 4, !dbg !32
  call void @llvm.dbg.value(metadata i32 %5, metadata !30, metadata !DIExpression()), !dbg !25
  call void @llvm.dbg.value(metadata i32 %5, metadata !30, metadata !DIExpression()), !dbg !25
  %6 = icmp ult i32 %5, 2, !dbg !33
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #3, !dbg !34
  br label %8, !dbg !35

8:                                                ; preds = %1, %4
  ret void, !dbg !35
}

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

declare void @klee_assume(i64 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathIsRelativeW(ptr noundef readnone %0) unnamed_addr #1 !dbg !36 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !39, metadata !DIExpression()), !dbg !40
  %3 = icmp eq ptr %0, null, !dbg !41
  br i1 %3, label %8, label %4, !dbg !43

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !44, metadata !DIExpression(DW_OP_deref)), !dbg !40
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.1) #3, !dbg !45
  %5 = load i32, ptr %2, align 4, !dbg !46
  call void @llvm.dbg.value(metadata i32 %5, metadata !44, metadata !DIExpression()), !dbg !40
  call void @llvm.dbg.value(metadata i32 %5, metadata !44, metadata !DIExpression()), !dbg !40
  %6 = icmp ult i32 %5, 2, !dbg !47
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #3, !dbg !48
  br label %8, !dbg !49

8:                                                ; preds = %1, %4
  ret void, !dbg !49
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathIsUNCW(ptr noundef readnone %0) unnamed_addr #1 !dbg !50 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !51, metadata !DIExpression()), !dbg !52
  %3 = icmp eq ptr %0, null, !dbg !53
  br i1 %3, label %8, label %4, !dbg !55

4:                                                ; preds = %1
  call void @llvm.dbg.value(metadata ptr %2, metadata !56, metadata !DIExpression(DW_OP_deref)), !dbg !52
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.2) #3, !dbg !57
  %5 = load i32, ptr %2, align 4, !dbg !58
  call void @llvm.dbg.value(metadata i32 %5, metadata !56, metadata !DIExpression()), !dbg !52
  call void @llvm.dbg.value(metadata i32 %5, metadata !56, metadata !DIExpression()), !dbg !52
  %6 = icmp ult i32 %5, 2, !dbg !59
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #3, !dbg !60
  br label %8, !dbg !61

8:                                                ; preds = %1, %4
  ret void, !dbg !61
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @PathStripToRootW() unnamed_addr #1 !dbg !62 {
  %1 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr poison, metadata !65, metadata !DIExpression()), !dbg !66
  call void @llvm.dbg.value(metadata ptr %1, metadata !67, metadata !DIExpression(DW_OP_deref)), !dbg !66
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 4, ptr noundef nonnull @.str.3) #3, !dbg !68
  %2 = load i32, ptr %1, align 4, !dbg !69
  call void @llvm.dbg.value(metadata i32 %2, metadata !67, metadata !DIExpression()), !dbg !66
  %3 = icmp ult i32 %2, 2, !dbg !70
  %4 = zext i1 %3 to i64
  call void @klee_assume(i64 noundef %4) #3, !dbg !71
  ret void, !dbg !72
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc ptr @PathCombineW(ptr noundef readonly %0, ptr noundef %1, ptr noundef %2) unnamed_addr #1 !dbg !73 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !77, metadata !DIExpression()), !dbg !78
  call void @llvm.dbg.value(metadata ptr %1, metadata !79, metadata !DIExpression()), !dbg !78
  call void @llvm.dbg.value(metadata ptr %2, metadata !80, metadata !DIExpression()), !dbg !78
  %.not = icmp eq ptr %0, null, !dbg !81
  br i1 %.not, label %10, label %4, !dbg !83

4:                                                ; preds = %3
  tail call fastcc void @PathIsRelativeW(ptr noundef %2), !dbg !84
  call void @llvm.dbg.value(metadata i32 0, metadata !85, metadata !DIExpression()), !dbg !78
  tail call fastcc void @PathIsUNCW(ptr noundef %1), !dbg !86
  call void @llvm.dbg.value(metadata i32 0, metadata !87, metadata !DIExpression()), !dbg !78
  tail call fastcc void @PathCanonicalizeW(ptr noundef %2), !dbg !88
  call void @llvm.dbg.value(metadata i32 0, metadata !89, metadata !DIExpression()), !dbg !78
  %.not4 = icmp eq ptr %1, null, !dbg !90
  br i1 %.not4, label %9, label %5, !dbg !92

5:                                                ; preds = %4
  %6 = load i16, ptr %1, align 2, !dbg !93
  %7 = icmp eq i16 %6, 0, !dbg !94
  br i1 %7, label %9, label %8, !dbg !95

8:                                                ; preds = %5
  tail call fastcc void @myPathAddBackslashW(ptr noundef nonnull %0), !dbg !96
  br label %9

9:                                                ; preds = %4, %5, %8
  tail call fastcc void @PathStripToRootW(), !dbg !98
  br label %10

10:                                               ; preds = %9, %3
  %.0 = phi ptr [ null, %3 ], [ %0, %9 ], !dbg !78
  ret ptr %.0, !dbg !99
}

; Function Attrs: noinline nounwind uwtable
define internal fastcc void @myPathAddBackslashW(ptr nocapture noundef readonly %0) unnamed_addr #1 !dbg !100 {
  %2 = alloca i32, align 4
  call void @llvm.dbg.value(metadata ptr %0, metadata !103, metadata !DIExpression()), !dbg !104
  call void @llvm.dbg.value(metadata ptr %2, metadata !105, metadata !DIExpression(DW_OP_deref)), !dbg !104
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 4, ptr noundef nonnull @.str.8) #3, !dbg !106
  %3 = load i32, ptr %2, align 4, !dbg !107
  call void @llvm.dbg.value(metadata i32 %3, metadata !105, metadata !DIExpression()), !dbg !104
  %4 = icmp ult i32 %3, 2, !dbg !108
  %5 = zext i1 %4 to i64
  call void @klee_assume(i64 noundef %5) #3, !dbg !109
  %6 = load i32, ptr %2, align 4, !dbg !110
  call void @llvm.dbg.value(metadata i32 %6, metadata !105, metadata !DIExpression()), !dbg !104
  %.not = icmp eq i32 %6, 0, !dbg !110
  br i1 %.not, label %11, label %7, !dbg !112

7:                                                ; preds = %1
  %8 = load i16, ptr %0, align 2, !dbg !113
  %9 = icmp ne i16 %8, 0, !dbg !114
  %10 = zext i1 %9 to i64
  call void @klee_assume(i64 noundef %10) #3, !dbg !115
  br label %11, !dbg !115

11:                                               ; preds = %7, %1
  ret void, !dbg !116
}

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #1 !dbg !117 {
  %1 = alloca [260 x i16], align 16
  %2 = alloca [260 x i16], align 16
  %3 = alloca [260 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !120, metadata !DIExpression()), !dbg !124
  call void @llvm.dbg.declare(metadata ptr %2, metadata !125, metadata !DIExpression()), !dbg !126
  call void @llvm.dbg.declare(metadata ptr %3, metadata !127, metadata !DIExpression()), !dbg !128
  call void @llvm.dbg.value(metadata i32 0, metadata !129, metadata !DIExpression()), !dbg !131
  br label %4, !dbg !132

4:                                                ; preds = %0, %4
  %indvars.iv = phi i64 [ 0, %0 ], [ %indvars.iv.next, %4 ]
  call void @llvm.dbg.value(metadata i64 %indvars.iv, metadata !129, metadata !DIExpression()), !dbg !131
  %5 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 %indvars.iv, !dbg !133
  store i16 0, ptr %5, align 2, !dbg !136
  %6 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 %indvars.iv, !dbg !137
  store i16 0, ptr %6, align 2, !dbg !138
  %7 = getelementptr inbounds [260 x i16], ptr %3, i64 0, i64 %indvars.iv, !dbg !139
  store i16 0, ptr %7, align 2, !dbg !140
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1, !dbg !141
  call void @llvm.dbg.value(metadata i64 %indvars.iv.next, metadata !129, metadata !DIExpression()), !dbg !131
  %exitcond.not = icmp eq i64 %indvars.iv.next, 260, !dbg !142
  br i1 %exitcond.not, label %8, label %4, !dbg !132, !llvm.loop !143

8:                                                ; preds = %4
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 520, ptr noundef nonnull @.str.5) #3, !dbg !146
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 520, ptr noundef nonnull @.str.6) #3, !dbg !147
  %9 = getelementptr inbounds [260 x i16], ptr %1, i64 0, i64 259, !dbg !148
  %10 = load i16, ptr %9, align 2, !dbg !148
  %11 = icmp eq i16 %10, 0, !dbg !149
  %12 = zext i1 %11 to i64
  call void @klee_assume(i64 noundef %12) #3, !dbg !150
  %13 = getelementptr inbounds [260 x i16], ptr %2, i64 0, i64 259, !dbg !151
  %14 = load i16, ptr %13, align 2, !dbg !151
  %15 = icmp eq i16 %14, 0, !dbg !152
  %16 = zext i1 %15 to i64
  call void @klee_assume(i64 noundef %16) #3, !dbg !153
  call void @klee_assume(i64 noundef 1) #3, !dbg !154
  call void @klee_assume(i64 noundef 1) #3, !dbg !155
  %17 = call fastcc ptr @PathCombineW(ptr noundef nonnull %3, ptr noundef nonnull %1, ptr noundef nonnull %2), !dbg !156
  call void @llvm.dbg.value(metadata ptr %17, metadata !157, metadata !DIExpression()), !dbg !158
  %.not = icmp eq ptr %17, null, !dbg !159
  br i1 %.not, label %21, label %18, !dbg !159

18:                                               ; preds = %8
  %19 = load i16, ptr %17, align 2, !dbg !160
  %20 = zext i16 %19 to i32, !dbg !160
  br label %21, !dbg !159

21:                                               ; preds = %8, %18
  %22 = phi i32 [ %20, %18 ], [ 0, %8 ], !dbg !159
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.7, i32 noundef %22) #3, !dbg !161
  ret i32 0, !dbg !162
}

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #0

attributes #0 = { nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #1 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!4, !5, !6, !7, !8, !9, !10}
!llvm.ident = !{!11}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Ubuntu clang version 14.0.0-1ubuntu1.1", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !2, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "harness_pathcombinew.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "c704bb366e3610bbb7f66213dc088977")
!2 = !{!3}
!3 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!4 = !{i32 7, !"Dwarf Version", i32 5}
!5 = !{i32 2, !"Debug Info Version", i32 3}
!6 = !{i32 1, !"wchar_size", i32 4}
!7 = !{i32 7, !"PIC Level", i32 2}
!8 = !{i32 7, !"PIE Level", i32 2}
!9 = !{i32 7, !"uwtable", i32 1}
!10 = !{i32 7, !"frame-pointer", i32 2}
!11 = !{!"Ubuntu clang version 14.0.0-1ubuntu1.1"}
!12 = distinct !DISubprogram(name: "PathCanonicalizeW", scope: !13, file: !13, line: 65, type: !14, scopeLine: 65, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
!13 = !DIFile(filename: "./oda_stubs.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "a43d5c360930fa4505fc901429adc83c")
!14 = !DISubroutineType(cc: DW_CC_nocall, types: !15)
!15 = !{!16, !18, !21}
!16 = !DIDerivedType(tag: DW_TAG_typedef, name: "BOOL", file: !13, line: 22, baseType: !17)
!17 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!18 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !19, size: 64)
!19 = !DIDerivedType(tag: DW_TAG_typedef, name: "WCHAR", file: !13, line: 19, baseType: !20)
!20 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!21 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !22, size: 64)
!22 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !19)
!23 = !{}
!24 = !DILocalVariable(name: "buffer", arg: 1, scope: !12, file: !13, line: 65, type: !18)
!25 = !DILocation(line: 0, scope: !12)
!26 = !DILocalVariable(name: "path", arg: 2, scope: !12, file: !13, line: 65, type: !21)
!27 = !DILocation(line: 66, column: 14, scope: !28)
!28 = distinct !DILexicalBlock(scope: !12, file: !13, line: 66, column: 9)
!29 = !DILocation(line: 66, column: 9, scope: !12)
!30 = !DILocalVariable(name: "ret", scope: !12, file: !13, line: 67, type: !16)
!31 = !DILocation(line: 68, column: 5, scope: !12)
!32 = !DILocation(line: 69, column: 17, scope: !12)
!33 = !DILocation(line: 69, column: 29, scope: !12)
!34 = !DILocation(line: 69, column: 5, scope: !12)
!35 = !DILocation(line: 70, column: 1, scope: !12)
!36 = distinct !DISubprogram(name: "PathIsRelativeW", scope: !13, file: !13, line: 80, type: !37, scopeLine: 80, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
!37 = !DISubroutineType(cc: DW_CC_nocall, types: !38)
!38 = !{!16, !21}
!39 = !DILocalVariable(name: "path", arg: 1, scope: !36, file: !13, line: 80, type: !21)
!40 = !DILocation(line: 0, scope: !36)
!41 = !DILocation(line: 81, column: 14, scope: !42)
!42 = distinct !DILexicalBlock(scope: !36, file: !13, line: 81, column: 9)
!43 = !DILocation(line: 81, column: 9, scope: !36)
!44 = !DILocalVariable(name: "ret", scope: !36, file: !13, line: 82, type: !16)
!45 = !DILocation(line: 83, column: 5, scope: !36)
!46 = !DILocation(line: 84, column: 17, scope: !36)
!47 = !DILocation(line: 84, column: 29, scope: !36)
!48 = !DILocation(line: 84, column: 5, scope: !36)
!49 = !DILocation(line: 85, column: 1, scope: !36)
!50 = distinct !DISubprogram(name: "PathIsUNCW", scope: !13, file: !13, line: 95, type: !37, scopeLine: 95, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
!51 = !DILocalVariable(name: "path", arg: 1, scope: !50, file: !13, line: 95, type: !21)
!52 = !DILocation(line: 0, scope: !50)
!53 = !DILocation(line: 96, column: 14, scope: !54)
!54 = distinct !DILexicalBlock(scope: !50, file: !13, line: 96, column: 9)
!55 = !DILocation(line: 96, column: 9, scope: !50)
!56 = !DILocalVariable(name: "ret", scope: !50, file: !13, line: 97, type: !16)
!57 = !DILocation(line: 98, column: 5, scope: !50)
!58 = !DILocation(line: 99, column: 17, scope: !50)
!59 = !DILocation(line: 99, column: 29, scope: !50)
!60 = !DILocation(line: 99, column: 5, scope: !50)
!61 = !DILocation(line: 100, column: 1, scope: !50)
!62 = distinct !DISubprogram(name: "PathStripToRootW", scope: !13, file: !13, line: 110, type: !63, scopeLine: 110, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
!63 = !DISubroutineType(cc: DW_CC_nocall, types: !64)
!64 = !{!16, !18}
!65 = !DILocalVariable(name: "path", arg: 1, scope: !62, file: !13, line: 110, type: !18)
!66 = !DILocation(line: 0, scope: !62)
!67 = !DILocalVariable(name: "ret", scope: !62, file: !13, line: 112, type: !16)
!68 = !DILocation(line: 113, column: 5, scope: !62)
!69 = !DILocation(line: 114, column: 17, scope: !62)
!70 = !DILocation(line: 114, column: 29, scope: !62)
!71 = !DILocation(line: 114, column: 5, scope: !62)
!72 = !DILocation(line: 115, column: 1, scope: !62)
!73 = distinct !DISubprogram(name: "PathCombineW", scope: !1, file: !1, line: 32, type: !74, scopeLine: 33, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
!74 = !DISubroutineType(types: !75)
!75 = !{!76, !18, !21, !21}
!76 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPWSTR", file: !13, line: 21, baseType: !18)
!77 = !DILocalVariable(name: "dst", arg: 1, scope: !73, file: !1, line: 32, type: !18)
!78 = !DILocation(line: 0, scope: !73)
!79 = !DILocalVariable(name: "dir", arg: 2, scope: !73, file: !1, line: 32, type: !21)
!80 = !DILocalVariable(name: "file", arg: 3, scope: !73, file: !1, line: 32, type: !21)
!81 = !DILocation(line: 34, column: 10, scope: !82)
!82 = distinct !DILexicalBlock(scope: !73, file: !1, line: 34, column: 9)
!83 = !DILocation(line: 34, column: 9, scope: !73)
!84 = !DILocation(line: 37, column: 17, scope: !73)
!85 = !DILocalVariable(name: "rel", scope: !73, file: !1, line: 37, type: !16)
!86 = !DILocation(line: 38, column: 17, scope: !73)
!87 = !DILocalVariable(name: "unc", scope: !73, file: !1, line: 38, type: !16)
!88 = !DILocation(line: 39, column: 18, scope: !73)
!89 = !DILocalVariable(name: "canon", scope: !73, file: !1, line: 39, type: !16)
!90 = !DILocation(line: 42, column: 10, scope: !91)
!91 = distinct !DILexicalBlock(scope: !73, file: !1, line: 42, column: 9)
!92 = !DILocation(line: 42, column: 14, scope: !91)
!93 = !DILocation(line: 42, column: 17, scope: !91)
!94 = !DILocation(line: 42, column: 24, scope: !91)
!95 = !DILocation(line: 42, column: 9, scope: !73)
!96 = !DILocation(line: 46, column: 9, scope: !97)
!97 = distinct !DILexicalBlock(scope: !91, file: !1, line: 44, column: 12)
!98 = !DILocation(line: 51, column: 5, scope: !73)
!99 = !DILocation(line: 62, column: 1, scope: !73)
!100 = distinct !DISubprogram(name: "myPathAddBackslashW", scope: !13, file: !13, line: 49, type: !101, scopeLine: 49, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !0, retainedNodes: !23)
!101 = !DISubroutineType(cc: DW_CC_nocall, types: !102)
!102 = !{!76, !76}
!103 = !DILocalVariable(name: "lpszPath", arg: 1, scope: !100, file: !13, line: 49, type: !76)
!104 = !DILocation(line: 0, scope: !100)
!105 = !DILocalVariable(name: "ret", scope: !100, file: !13, line: 51, type: !16)
!106 = !DILocation(line: 52, column: 5, scope: !100)
!107 = !DILocation(line: 53, column: 17, scope: !100)
!108 = !DILocation(line: 53, column: 29, scope: !100)
!109 = !DILocation(line: 53, column: 5, scope: !100)
!110 = !DILocation(line: 54, column: 9, scope: !111)
!111 = distinct !DILexicalBlock(scope: !100, file: !13, line: 54, column: 9)
!112 = !DILocation(line: 54, column: 9, scope: !100)
!113 = !DILocation(line: 54, column: 26, scope: !111)
!114 = !DILocation(line: 54, column: 38, scope: !111)
!115 = !DILocation(line: 54, column: 14, scope: !111)
!116 = !DILocation(line: 55, column: 1, scope: !100)
!117 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 64, type: !118, scopeLine: 65, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !23)
!118 = !DISubroutineType(types: !119)
!119 = !{!17}
!120 = !DILocalVariable(name: "dir", scope: !117, file: !1, line: 67, type: !121)
!121 = !DICompositeType(tag: DW_TAG_array_type, baseType: !19, size: 4160, elements: !122)
!122 = !{!123}
!123 = !DISubrange(count: 260)
!124 = !DILocation(line: 67, column: 11, scope: !117)
!125 = !DILocalVariable(name: "file", scope: !117, file: !1, line: 68, type: !121)
!126 = !DILocation(line: 68, column: 11, scope: !117)
!127 = !DILocalVariable(name: "dst", scope: !117, file: !1, line: 69, type: !121)
!128 = !DILocation(line: 69, column: 11, scope: !117)
!129 = !DILocalVariable(name: "i", scope: !130, file: !1, line: 72, type: !17)
!130 = distinct !DILexicalBlock(scope: !117, file: !1, line: 72, column: 5)
!131 = !DILocation(line: 0, scope: !130)
!132 = !DILocation(line: 72, column: 5, scope: !130)
!133 = !DILocation(line: 73, column: 9, scope: !134)
!134 = distinct !DILexicalBlock(scope: !135, file: !1, line: 72, column: 40)
!135 = distinct !DILexicalBlock(scope: !130, file: !1, line: 72, column: 5)
!136 = !DILocation(line: 73, column: 16, scope: !134)
!137 = !DILocation(line: 74, column: 9, scope: !134)
!138 = !DILocation(line: 74, column: 17, scope: !134)
!139 = !DILocation(line: 75, column: 9, scope: !134)
!140 = !DILocation(line: 75, column: 16, scope: !134)
!141 = !DILocation(line: 72, column: 36, scope: !135)
!142 = !DILocation(line: 72, column: 23, scope: !135)
!143 = distinct !{!143, !132, !144, !145}
!144 = !DILocation(line: 76, column: 5, scope: !130)
!145 = !{!"llvm.loop.mustprogress"}
!146 = !DILocation(line: 78, column: 5, scope: !117)
!147 = !DILocation(line: 79, column: 5, scope: !117)
!148 = !DILocation(line: 82, column: 17, scope: !117)
!149 = !DILocation(line: 82, column: 33, scope: !117)
!150 = !DILocation(line: 82, column: 5, scope: !117)
!151 = !DILocation(line: 83, column: 17, scope: !117)
!152 = !DILocation(line: 83, column: 34, scope: !117)
!153 = !DILocation(line: 83, column: 5, scope: !117)
!154 = !DILocation(line: 86, column: 5, scope: !117)
!155 = !DILocation(line: 87, column: 5, scope: !117)
!156 = !DILocation(line: 90, column: 18, scope: !117)
!157 = !DILocalVariable(name: "out", scope: !117, file: !1, line: 90, type: !76)
!158 = !DILocation(line: 0, scope: !117)
!159 = !DILocation(line: 93, column: 42, scope: !117)
!160 = !DILocation(line: 93, column: 48, scope: !117)
!161 = !DILocation(line: 93, column: 5, scope: !117)
!162 = !DILocation(line: 95, column: 5, scope: !117)
