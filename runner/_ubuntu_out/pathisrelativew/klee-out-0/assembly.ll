; ModuleID = 'harness.bc'
source_filename = "harness_pathisrelativew.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@.str = private unnamed_addr constant [5 x i8] c"path\00", align 1
@.str.1 = private unnamed_addr constant [24 x i8] c"PathIsRelativeW(result)\00", align 1

; Function Attrs: argmemonly mustprogress nofree noinline norecurse nosync nounwind readonly willreturn uwtable
define internal fastcc i32 @PathIsRelativeW(ptr noundef readonly %0) unnamed_addr #0 !dbg !10 {
  call void @llvm.dbg.value(metadata ptr %0, metadata !21, metadata !DIExpression()), !dbg !22
  %.not = icmp eq ptr %0, null, !dbg !23
  br i1 %.not, label %8, label %2, !dbg !25

2:                                                ; preds = %1
  %3 = load i16, ptr %0, align 2, !dbg !26
  switch i16 %3, label %4 [
    i16 0, label %8
    i16 92, label %.fold.split
  ], !dbg !28

4:                                                ; preds = %2
  %5 = getelementptr inbounds i16, ptr %0, i64 1, !dbg !29
  %6 = load i16, ptr %5, align 2, !dbg !29
  %7 = icmp ne i16 %6, 58, !dbg !31
  %spec.select = zext i1 %7 to i32, !dbg !32
  br label %8, !dbg !32

.fold.split:                                      ; preds = %2
  br label %8, !dbg !33

8:                                                ; preds = %4, %2, %.fold.split, %1
  %.0 = phi i32 [ 1, %1 ], [ 1, %2 ], [ 0, %.fold.split ], [ %spec.select, %4 ], !dbg !22
  ret i32 %.0, !dbg !33
}

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() local_unnamed_addr #2 !dbg !34 {
  %1 = alloca [32 x i16], align 16
  call void @llvm.dbg.declare(metadata ptr %1, metadata !37, metadata !DIExpression()), !dbg !41
  call void @llvm.dbg.value(metadata i32 0, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 0, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 1, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 1, metadata !42, metadata !DIExpression()), !dbg !44
  %2 = getelementptr inbounds [32 x i16], ptr %1, i64 0, i64 1, !dbg !45
  call void @llvm.dbg.value(metadata i64 2, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 2, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 3, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 3, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 4, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 4, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 5, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 5, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 6, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 6, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 7, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 7, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 8, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 8, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 9, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 9, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 10, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 10, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 11, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 11, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 12, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 12, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 13, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 13, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 14, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 14, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 15, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 15, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 16, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 16, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 17, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 17, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 18, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 18, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 19, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 19, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 20, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 20, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 21, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 21, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 22, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 22, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 23, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 23, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 24, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 24, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 25, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 25, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 26, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 26, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 27, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 27, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 28, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 28, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 29, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 29, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 30, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 30, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 31, metadata !42, metadata !DIExpression()), !dbg !44
  call void @llvm.dbg.value(metadata i64 31, metadata !42, metadata !DIExpression()), !dbg !44
  %3 = getelementptr inbounds [32 x i16], ptr %1, i64 0, i64 31, !dbg !45
  call void @llvm.dbg.value(metadata i64 32, metadata !42, metadata !DIExpression()), !dbg !44
  %4 = call ptr @memset(ptr %1, i32 0, i64 64), !dbg !47
  call void @klee_make_symbolic(ptr noundef nonnull %1, i64 noundef 64, ptr noundef nonnull @.str) #5, !dbg !48
  %5 = load i16, ptr %3, align 2, !dbg !49
  %6 = icmp eq i16 %5, 0, !dbg !50
  %7 = zext i1 %6 to i64
  call void @klee_assume(i64 noundef %7) #5, !dbg !51
  %8 = load i16, ptr %1, align 16, !dbg !52
  call void @llvm.dbg.value(metadata i16 %8, metadata !53, metadata !DIExpression()), !dbg !54
  %9 = load i16, ptr %2, align 2, !dbg !55
  call void @llvm.dbg.value(metadata i16 %9, metadata !56, metadata !DIExpression()), !dbg !54
  %10 = icmp eq i16 %8, 92, !dbg !57
  br i1 %10, label %.thread10, label %11, !dbg !58

.thread10:                                        ; preds = %0
  call void @klee_assume(i64 noundef 1) #5, !dbg !59
  br label %30, !dbg !60

11:                                               ; preds = %0
  %12 = add i16 %8, -65, !dbg !62
  %13 = icmp ult i16 %12, 26, !dbg !62
  br i1 %13, label %17, label %14, !dbg !62

14:                                               ; preds = %11
  %15 = add i16 %8, -97, !dbg !63
  %16 = icmp ult i16 %15, 26, !dbg !63
  br i1 %16, label %.thread8, label %18, !dbg !63

.thread8:                                         ; preds = %14
  call void @klee_assume(i64 noundef 1) #5, !dbg !59
  br label %21, !dbg !60

17:                                               ; preds = %11
  call void @klee_assume(i64 noundef 1) #5, !dbg !59
  br label %21

18:                                               ; preds = %14
  %19 = add i16 %8, -48, !dbg !64
  %20 = icmp ult i16 %19, 10, !dbg !64
  %phi.cast1 = zext i1 %20 to i64, !dbg !65
  call void @klee_assume(i64 noundef %phi.cast1) #5, !dbg !59
  br label %30

21:                                               ; preds = %.thread8, %17
  switch i16 %9, label %22 [
    i16 58, label %28
    i16 0, label %28
  ], !dbg !66

22:                                               ; preds = %21
  %23 = add i16 %9, -48, !dbg !68
  %24 = icmp ult i16 %23, 10, !dbg !68
  %25 = icmp eq i16 %9, 92
  %or.cond7 = or i1 %25, %24, !dbg !68
  br i1 %or.cond7, label %28, label %26, !dbg !68

26:                                               ; preds = %22
  %27 = icmp eq i16 %9, 47, !dbg !69
  %phi.cast2 = zext i1 %27 to i64, !dbg !70
  br label %28, !dbg !70

28:                                               ; preds = %22, %21, %21, %26
  %29 = phi i64 [ 1, %21 ], [ %phi.cast2, %26 ], [ 1, %21 ], [ 1, %22 ]
  call void @klee_assume(i64 noundef %29) #5, !dbg !71
  br label %30, !dbg !72

30:                                               ; preds = %18, %.thread10, %28
  %31 = call fastcc i32 @PathIsRelativeW(ptr noundef nonnull %1), !dbg !73, !range !74
  call void @llvm.dbg.value(metadata i32 %31, metadata !75, metadata !DIExpression()), !dbg !54
  call void (ptr, ...) @klee_print_expr(ptr noundef nonnull @.str.1, i32 noundef %31) #5, !dbg !76
  ret i32 0, !dbg !77
}

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) local_unnamed_addr #3

declare void @klee_assume(i64 noundef) local_unnamed_addr #3

declare void @klee_print_expr(ptr noundef, ...) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind readnone speculatable willreturn
declare void @llvm.dbg.value(metadata, metadata, metadata) #1

; Function Attrs: argmemonly mustprogress nocallback nofree nounwind willreturn writeonly
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

declare ptr @memset(ptr, i32, i64)

attributes #0 = { argmemonly mustprogress nofree noinline norecurse nosync nounwind readonly willreturn uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind readnone speculatable willreturn }
attributes #2 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { argmemonly mustprogress nocallback nofree nounwind willreturn writeonly }
attributes #5 = { nounwind }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "Ubuntu clang version 14.0.0-1ubuntu1.1", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "harness_pathisrelativew.c", directory: "/home/guren/oda_work/oda_demo/klee", checksumkind: CSK_MD5, checksum: "e19ed31c7c0cbda4869769d60e386901")
!2 = !{i32 7, !"Dwarf Version", i32 5}
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = !{i32 1, !"wchar_size", i32 4}
!5 = !{i32 7, !"PIC Level", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
!7 = !{i32 7, !"uwtable", i32 1}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{!"Ubuntu clang version 14.0.0-1ubuntu1.1"}
!10 = distinct !DISubprogram(name: "PathIsRelativeW", scope: !1, file: !1, line: 37, type: !11, scopeLine: 38, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
!11 = !DISubroutineType(types: !12)
!12 = !{!13, !15}
!13 = !DIDerivedType(tag: DW_TAG_typedef, name: "BOOL", file: !1, line: 19, baseType: !14)
!14 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!15 = !DIDerivedType(tag: DW_TAG_typedef, name: "LPCWSTR", file: !1, line: 18, baseType: !16)
!16 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !17, size: 64)
!17 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !18)
!18 = !DIDerivedType(tag: DW_TAG_typedef, name: "WCHAR", file: !1, line: 17, baseType: !19)
!19 = !DIBasicType(name: "unsigned short", size: 16, encoding: DW_ATE_unsigned)
!20 = !{}
!21 = !DILocalVariable(name: "lpszPath", arg: 1, scope: !10, file: !1, line: 37, type: !15)
!22 = !DILocation(line: 0, scope: !10)
!23 = !DILocation(line: 40, column: 10, scope: !24)
!24 = distinct !DILexicalBlock(scope: !10, file: !1, line: 40, column: 9)
!25 = !DILocation(line: 40, column: 9, scope: !10)
!26 = !DILocation(line: 44, column: 10, scope: !27)
!27 = distinct !DILexicalBlock(scope: !10, file: !1, line: 44, column: 9)
!28 = !DILocation(line: 44, column: 9, scope: !10)
!29 = !DILocation(line: 53, column: 24, scope: !30)
!30 = distinct !DILexicalBlock(scope: !10, file: !1, line: 53, column: 9)
!31 = !DILocation(line: 53, column: 36, scope: !30)
!32 = !DILocation(line: 53, column: 9, scope: !10)
!33 = !DILocation(line: 58, column: 1, scope: !10)
!34 = distinct !DISubprogram(name: "main", scope: !1, file: !1, line: 60, type: !35, scopeLine: 61, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !20)
!35 = !DISubroutineType(types: !36)
!36 = !{!14}
!37 = !DILocalVariable(name: "path", scope: !34, file: !1, line: 64, type: !38)
!38 = !DICompositeType(tag: DW_TAG_array_type, baseType: !18, size: 512, elements: !39)
!39 = !{!40}
!40 = !DISubrange(count: 32)
!41 = !DILocation(line: 64, column: 11, scope: !34)
!42 = !DILocalVariable(name: "i", scope: !43, file: !1, line: 75, type: !14)
!43 = distinct !DILexicalBlock(scope: !34, file: !1, line: 75, column: 5)
!44 = !DILocation(line: 0, scope: !43)
!45 = !DILocation(line: 75, column: 34, scope: !46)
!46 = distinct !DILexicalBlock(scope: !43, file: !1, line: 75, column: 5)
!47 = !DILocation(line: 75, column: 42, scope: !46)
!48 = !DILocation(line: 76, column: 5, scope: !34)
!49 = !DILocation(line: 77, column: 17, scope: !34)
!50 = !DILocation(line: 77, column: 26, scope: !34)
!51 = !DILocation(line: 77, column: 5, scope: !34)
!52 = !DILocation(line: 90, column: 16, scope: !34)
!53 = !DILocalVariable(name: "p0", scope: !34, file: !1, line: 90, type: !18)
!54 = !DILocation(line: 0, scope: !34)
!55 = !DILocation(line: 91, column: 16, scope: !34)
!56 = !DILocalVariable(name: "p1", scope: !34, file: !1, line: 91, type: !18)
!57 = !DILocation(line: 92, column: 20, scope: !34)
!58 = !DILocation(line: 92, column: 28, scope: !34)
!59 = !DILocation(line: 92, column: 5, scope: !34)
!60 = !DILocation(line: 98, column: 48, scope: !61)
!61 = distinct !DILexicalBlock(scope: !34, file: !1, line: 98, column: 9)
!62 = !DILocation(line: 92, column: 42, scope: !34)
!63 = !DILocation(line: 92, column: 70, scope: !34)
!64 = !DILocation(line: 92, column: 98, scope: !34)
!65 = !DILocation(line: 92, column: 84, scope: !34)
!66 = !DILocation(line: 100, column: 31, scope: !67)
!67 = distinct !DILexicalBlock(scope: !61, file: !1, line: 99, column: 5)
!68 = !DILocation(line: 100, column: 56, scope: !67)
!69 = !DILocation(line: 100, column: 90, scope: !67)
!70 = !DILocation(line: 100, column: 84, scope: !67)
!71 = !DILocation(line: 100, column: 9, scope: !67)
!72 = !DILocation(line: 101, column: 5, scope: !67)
!73 = !DILocation(line: 112, column: 19, scope: !34)
!74 = !{i32 0, i32 2}
!75 = !DILocalVariable(name: "result", scope: !34, file: !1, line: 112, type: !13)
!76 = !DILocation(line: 125, column: 5, scope: !34)
!77 = !DILocation(line: 127, column: 5, scope: !34)
