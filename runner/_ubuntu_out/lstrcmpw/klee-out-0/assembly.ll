; ModuleID = 'harness.bc'
source_filename = "harness_lstrcmpw.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [2 x i8] c"a\00", align 1
@.str.1 = private unnamed_addr constant [2 x i8] c"b\00", align 1
@.str.2 = private unnamed_addr constant [15 x i8] c"lstrcmpW(norm)\00", align 1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #0 !dbg !10 {
  %1 = alloca [16 x i16], align 16
  %2 = alloca [16 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !15, metadata !DIExpression()), !dbg !21
  call void @llvm.dbg.declare(metadata ptr %2, metadata !22, metadata !DIExpression()), !dbg !23
  call void @llvm.dbg.value(metadata i32 0, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 0, metadata !24, metadata !DIExpression()), !dbg !26
  store i16 0, ptr %1, align 16, !dbg !27
  store i16 0, ptr %2, align 16, !dbg !30
  call void @llvm.dbg.value(metadata i64 1, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 1, metadata !24, metadata !DIExpression()), !dbg !26
  %3 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 1, !dbg !31
  store i16 0, ptr %3, align 2, !dbg !27
  %4 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 1, !dbg !32
  store i16 0, ptr %4, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 2, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 2, metadata !24, metadata !DIExpression()), !dbg !26
  %5 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 2, !dbg !31
  store i16 0, ptr %5, align 4, !dbg !27
  %6 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 2, !dbg !32
  store i16 0, ptr %6, align 4, !dbg !30
  call void @llvm.dbg.value(metadata i64 3, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 3, metadata !24, metadata !DIExpression()), !dbg !26
  %7 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 3, !dbg !31
  store i16 0, ptr %7, align 2, !dbg !27
  %8 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 3, !dbg !32
  store i16 0, ptr %8, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 4, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 4, metadata !24, metadata !DIExpression()), !dbg !26
  %9 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 4, !dbg !31
  store i16 0, ptr %9, align 8, !dbg !27
  %10 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 4, !dbg !32
  store i16 0, ptr %10, align 8, !dbg !30
  call void @llvm.dbg.value(metadata i64 5, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 5, metadata !24, metadata !DIExpression()), !dbg !26
  %11 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 5, !dbg !31
  store i16 0, ptr %11, align 2, !dbg !27
  %12 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 5, !dbg !32
  store i16 0, ptr %12, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 6, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 6, metadata !24, metadata !DIExpression()), !dbg !26
  %13 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 6, !dbg !31
  store i16 0, ptr %13, align 4, !dbg !27
  %14 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 6, !dbg !32
  store i16 0, ptr %14, align 4, !dbg !30
  call void @llvm.dbg.value(metadata i64 7, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 7, metadata !24, metadata !DIExpression()), !dbg !26
  %15 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 7, !dbg !31
  store i16 0, ptr %15, align 2, !dbg !27
  %16 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 7, !dbg !32
  store i16 0, ptr %16, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 8, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 8, metadata !24, metadata !DIExpression()), !dbg !26
  %17 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 8, !dbg !31
  store i16 0, ptr %17, align 16, !dbg !27
  %18 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 8, !dbg !32
  store i16 0, ptr %18, align 16, !dbg !30
  call void @llvm.dbg.value(metadata i64 9, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 9, metadata !24, metadata !DIExpression()), !dbg !26
  %19 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 9, !dbg !31
  store i16 0, ptr %19, align 2, !dbg !27
  %20 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 9, !dbg !32
  store i16 0, ptr %20, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 10, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 10, metadata !24, metadata !DIExpression()), !dbg !26
  %21 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 10, !dbg !31
  store i16 0, ptr %21, align 4, !dbg !27
  %22 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 10, !dbg !32
  store i16 0, ptr %22, align 4, !dbg !30
  call void @llvm.dbg.value(metadata i64 11, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 11, metadata !24, metadata !DIExpression()), !dbg !26
  %23 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 11, !dbg !31
  store i16 0, ptr %23, align 2, !dbg !27
  %24 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 11, !dbg !32
  store i16 0, ptr %24, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 12, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 12, metadata !24, metadata !DIExpression()), !dbg !26
  %25 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 12, !dbg !31
  store i16 0, ptr %25, align 8, !dbg !27
  %26 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 12, !dbg !32
  store i16 0, ptr %26, align 8, !dbg !30
  call void @llvm.dbg.value(metadata i64 13, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 13, metadata !24, metadata !DIExpression()), !dbg !26
  %27 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 13, !dbg !31
  store i16 0, ptr %27, align 2, !dbg !27
  %28 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 13, !dbg !32
  store i16 0, ptr %28, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 14, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 14, metadata !24, metadata !DIExpression()), !dbg !26
  %29 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 14, !dbg !31
  store i16 0, ptr %29, align 4, !dbg !27
  %30 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 14, !dbg !32
  store i16 0, ptr %30, align 4, !dbg !30
  call void @llvm.dbg.value(metadata i64 15, metadata !24, metadata !DIExpression()), !dbg !26
  call void @llvm.dbg.value(metadata i64 15, metadata !24, metadata !DIExpression()), !dbg !26
  %31 = getelementptr inbounds [16 x i16], ptr %1, i64 0, i64 15, !dbg !31
  store i16 0, ptr %31, align 2, !dbg !27
  %32 = getelementptr inbounds [16 x i16], ptr %2, i64 0, i64 15, !dbg !32
  store i16 0, ptr %32, align 2, !dbg !30
  call void @llvm.dbg.value(metadata i64 16, metadata !24, metadata !DIExpression()), !dbg !26
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 32, ptr noundef nonnull @.str) #4, !dbg !33
  call void @klee_make_symbolic(ptr noundef nonnull %2, i64 noundef 32, ptr noundef nonnull @.str.1) #4, !dbg !34
  %33 = load i16, ptr %31, align 2, !dbg !35
  %34 = icmp eq i16 %33, 0, !dbg !36
  %35 = zext i1 %34 to i64
  call void @klee_assume(i64 noundef %35) #4, !dbg !37
  %36 = load i16, ptr %32, align 2, !dbg !38
  %37 = icmp eq i16 %36, 0, !dbg !39
  %38 = zext i1 %37 to i64
  call void @klee_assume(i64 noundef %38) #4, !dbg !40
  %39 = load i16, ptr %1, align 16, !dbg !41
  call void @llvm.dbg.value(metadata i16 %39, metadata !42, metadata !DIExpression()), !dbg !43
  %40 = load i16, ptr %2, align 16, !dbg !44
  call void @llvm.dbg.value(metadata i16 %40, metadata !45, metadata !DIExpression()), !dbg !43
  %41 = icmp eq i16 %39, 0, !dbg !46
  %42 = and i16 %39, -33, !dbg !47
  %43 = add i16 %42, -65, !dbg !47
  %44 = icmp ult i16 %43, 26, !dbg !47
  %45 = or i1 %41, %44, !dbg !47
  %46 = add i16 %39, -48, !dbg !47
  %47 = icmp ult i16 %46, 10, !dbg !47
  %narrow = or i1 %47, %45, !dbg !47
  %48 = zext i1 %narrow to i64, !dbg !47
  call void @klee_assume(i64 noundef %48) #4, !dbg !48
  %49 = icmp eq i16 %40, 0, !dbg !49
  %50 = and i16 %40, -33, !dbg !50
  %51 = add i16 %50, -65, !dbg !50
  %52 = icmp ult i16 %51, 26, !dbg !50
  %53 = or i1 %49, %52, !dbg !50
  %54 = add i16 %40, -48, !dbg !50
  %55 = icmp ult i16 %54, 10, !dbg !50
  %narrow13 = or i1 %55, %53, !dbg !50
  %56 = zext i1 %narrow13 to i64, !dbg !50
  call void @klee_assume(i64 noundef %56) #4, !dbg !51
  %57 = call fastcc i32 @harness_lstrcmpW(ptr noundef nonnull %1, ptr noundef nonnull %2), !dbg !52, !range !53
  call void @llvm.dbg.value(metadata i32 %57, metadata !54, metadata !DIExpression()), !dbg !43
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.2, i32 noundef %57) #4, !dbg !55
  ret i32 0, !dbg !56
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

declare void @klee_assume(i64 noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind readonly uwtable
define internal fastcc i32 @harness_lstrcmpW(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1) unnamed_addr #3 !dbg !57 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !63, metadata !DIExpression()), !dbg !64
  call void @llvm.dbg.value(metadata ptr %1, metadata !65, metadata !DIExpression()), !dbg !64
  %3 = load i16, ptr %0, align 2, !dbg !66
  %.not4 = icmp eq i16 %3, 0, !dbg !66
  br i1 %.not4, label %.critedge, label %.lr.ph, !dbg !67

.lr.ph:                                           ; preds = %2, %7
  %4 = phi i16 [ %10, %7 ], [ %3, %2 ]
  %.016 = phi ptr [ %8, %7 ], [ %0, %2 ]
  %.025 = phi ptr [ %9, %7 ], [ %1, %2 ]
  call void @llvm.dbg.value(metadata ptr %.016, metadata !63, metadata !DIExpression()), !dbg !64
  call void @llvm.dbg.value(metadata ptr %.025, metadata !65, metadata !DIExpression()), !dbg !64
  %5 = load i16, ptr %.025, align 2, !dbg !68
  %.not3 = icmp ne i16 %5, 0, !dbg !68
  %6 = icmp eq i16 %4, %5
  %or.cond = select i1 %.not3, i1 %6, i1 false, !dbg !69
  br i1 %or.cond, label %7, label %.critedge, !dbg !69

7:                                                ; preds = %.lr.ph
  %8 = getelementptr inbounds i16, ptr %.016, i64 1, !dbg !70
  call void @llvm.dbg.value(metadata ptr %8, metadata !63, metadata !DIExpression()), !dbg !64
  %9 = getelementptr inbounds i16, ptr %.025, i64 1, !dbg !72
  call void @llvm.dbg.value(metadata ptr %9, metadata !65, metadata !DIExpression()), !dbg !64
  %10 = load i16, ptr %8, align 2, !dbg !66
  %.not = icmp eq i16 %10, 0, !dbg !66
  br i1 %.not, label %.critedge, label %.lr.ph, !dbg !67, !llvm.loop !73

.critedge:                                        ; preds = %7, %.lr.ph, %2
  %11 = phi i16 [ 0, %2 ], [ 0, %7 ], [ %4, %.lr.ph ], !dbg !77
  %.02.lcssa = phi ptr [ %1, %2 ], [ %9, %7 ], [ %.025, %.lr.ph ]
  %12 = load i16, ptr %.02.lcssa, align 2, !dbg !79
  %13 = icmp eq i16 %11, %12, !dbg !80
  %14 = icmp ult i16 %11, %12, !dbg !81
  %15 = select i1 %14, i32 -1, i32 1, !dbg !81
  %.0 = select i1 %13, i32 0, i32 %15, !dbg !81
  ret i32 %.0, !dbg !82
}

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind readonly uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Ubuntu clang version 14.0.0-1ubuntu1.1", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "harness_lstrcmpw.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "3467afce51e7ee304bcaad9c6b939ec1")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 1}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{!"Ubuntu clang version 14.0.0-1ubuntu1.1"}
!10 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 28, type: !11, scopeLine: 29, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{}
!15 = !DILocalVariable(name: "a", scope: !10, file: !1, line: 31, type: !16)
!16 = !DICompositeType(tag: DW_TAG_array_type, baseType: !17, size: 256, elements: !19)
!17 = !DIDerivedType(tag: DW_TAG_typedef, name: "WCHAR", file: !1, line: 17, baseType: !18)
!18 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!19 = !{!20}
!20 = !DISubrange(count: 16)
!21 = !DILocation(line: 31, column: 11, scope: !10)
!22 = !DILocalVariable(name: "b", scope: !10, file: !1, line: 32, type: !16)
!23 = !DILocation(line: 32, column: 11, scope: !10)
!24 = !DILocalVariable(name: "i", scope: !25, file: !1, line: 34, type: !13)
!25 = distinct !DILexicalBlock(scope: !10, file: !1, line: 34, column: 5)
!26 = !DILocation(line: 0, scope: !25)
!27 = !DILocation(line: 34, column: 41, scope: !28)
!28 = distinct !DILexicalBlock(scope: !29, file: !1, line: 34, column: 34)
!29 = distinct !DILexicalBlock(scope: !25, file: !1, line: 34, column: 5)
!30 = !DILocation(line: 34, column: 51, scope: !28)
!31 = !DILocation(line: 34, column: 36, scope: !28)
!32 = !DILocation(line: 34, column: 46, scope: !28)
!33 = !DILocation(line: 35, column: 5, scope: !10)
!34 = !DILocation(line: 36, column: 5, scope: !10)
!35 = !DILocation(line: 37, column: 17, scope: !10)
!36 = !DILocation(line: 37, column: 23, scope: !10)
!37 = !DILocation(line: 37, column: 5, scope: !10)
!38 = !DILocation(line: 38, column: 17, scope: !10)
!39 = !DILocation(line: 38, column: 23, scope: !10)
!40 = !DILocation(line: 38, column: 5, scope: !10)
!41 = !DILocation(line: 41, column: 16, scope: !10)
!42 = !DILocalVariable(name: "a0", scope: !10, file: !1, line: 41, type: !17)
!43 = !DILocation(line: 0, scope: !10)
!44 = !DILocation(line: 41, column: 27, scope: !10)
!45 = !DILocalVariable(name: "b0", scope: !10, file: !1, line: 41, type: !17)
!46 = !DILocation(line: 42, column: 20, scope: !10)
!47 = !DILocation(line: 42, column: 25, scope: !10)
!48 = !DILocation(line: 42, column: 5, scope: !10)
!49 = !DILocation(line: 43, column: 20, scope: !10)
!50 = !DILocation(line: 43, column: 25, scope: !10)
!51 = !DILocation(line: 43, column: 5, scope: !10)
!52 = !DILocation(line: 46, column: 13, scope: !10)
!53 = !{i32 -1, i32 2}
!54 = !DILocalVariable(name: "r", scope: !10, file: !1, line: 46, type: !13)
!55 = !DILocation(line: 51, column: 5, scope: !10)
!56 = !DILocation(line: 52, column: 5, scope: !10)
!57 = distinct !DISubprogram(name: "harness_lstrcmpW", scope: !1, file: !1, line: 20, type: !58, scopeLine: 21, flags: DIFlagPrototyped, spFlags: DISPFlagLocalToUnit | DISPFlagDefinition, unit: !0, retainedNodes: !14)
!58 = !DISubroutineType(types: !59)
!59 = !{!13, !60, !60}
!60 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPCWSTR", file: !1, line: 18, baseType: !61)
!61 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !62, size: 64)
!62 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !17)
!63 = !DILocalVariable(name: "a", arg: 1, scope: !57, file: !1, line: 20, type: !60)
!64 = !DILocation(line: 0, scope: !57)
!65 = !DILocalVariable(name: "b", arg: 2, scope: !57, file: !1, line: 20, type: !60)
!66 = !DILocation(line: 23, column: 12, scope: !57)
!67 = !DILocation(line: 23, column: 15, scope: !57)
!68 = !DILocation(line: 23, column: 18, scope: !57)
!69 = !DILocation(line: 23, column: 21, scope: !57)
!70 = !DILocation(line: 23, column: 37, scope: !71)
!71 = distinct !DILexicalBlock(scope: !57, file: !1, line: 23, column: 34)
!72 = !DILocation(line: 23, column: 42, scope: !71)
!73 = distinct !{!73, !74, !75, !76}
!74 = !DILocation(line: 23, column: 5, scope: !57)
!75 = !DILocation(line: 23, column: 46, scope: !57)
!76 = !{!"llvm.loop.mustprogress"}
!77 = !DILocation(line: 24, column: 9, scope: !78)
!78 = distinct !DILexicalBlock(scope: !57, file: !1, line: 24, column: 9)
!79 = !DILocation(line: 24, column: 15, scope: !78)
!80 = !DILocation(line: 24, column: 12, scope: !78)
!81 = !DILocation(line: 24, column: 9, scope: !57)
!82 = !DILocation(line: 26, column: 1, scope: !57)
