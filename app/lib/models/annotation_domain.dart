enum AnnotationDomain {
  surfaceTreatment,
  welding,
  cutting,
  cable,
  pipe,
  foamSpray,
  unknown,
}

extension AnnotationDomainX on AnnotationDomain {
  String get label => switch (this) {
        AnnotationDomain.surfaceTreatment => '표면처리',
        AnnotationDomain.welding => '용접',
        AnnotationDomain.cutting => '절단',
        AnnotationDomain.cable => '케이블',
        AnnotationDomain.pipe => '파이프',
        AnnotationDomain.foamSpray => '폼스프레이',
        AnnotationDomain.unknown => '기타',
      };

  // 백엔드 annotation_domain 문자열 → enum
  static AnnotationDomain fromString(String value) => switch (value) {
        'surface_treatment' => AnnotationDomain.surfaceTreatment,
        'welding' => AnnotationDomain.welding,
        'cutting' => AnnotationDomain.cutting,
        'cable' => AnnotationDomain.cable,
        'pipe' => AnnotationDomain.pipe,
        'foam_spray' => AnnotationDomain.foamSpray,
        _ => AnnotationDomain.unknown,
      };
}
