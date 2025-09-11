function "default_distros" {
  params = []
  result = ["noble"]
}
function "default_qtcreators" {
  params = []
  result = [
    {version: "17.0.0", url: "https://github.com/qt-creator/qt-creator/releases/download/v17.0.1/qtcreator-linux-x64-17.0.1.7z"},
    {version: "17.0.1-patched", url: "https://github.com/hicknhack-software/Qt-Creator/releases/download/v17.0.1-patched-2025-08-22/qtcreator-linux-x64-17475136203.7z"}
  ]
}
function "default_clangs" {
  params = []
  result = [
    // {major: 17, source: "apt"},
    {major: 18, source: "llvm"},
    {major: 19, source: "llvm"},
    {major: 20, source: "llvm"},
    {major: 21, source: "llvm"}
  ]
}
function "default_gccs" {
  params = []
  result = [
    // {major: 12, source: "apt"},
    {major: 13, source: "apt", distro: "noble"},
    {major: 14, source: "apt", distro: "noble"},
    {major: 15, source: "apt", distro: "plucky"}
  ]
}
function "default_qts" {
  params = []
  result = [
    {version: "6.7.3", arch: "linux_gcc_64"},
    {version: "6.8.3", arch: "linux_gcc_64"},
    {version: "6.9.2", arch: "linux_gcc_64"}
  ]
}

# note: we do not support multi distro build right now!
variable "ALL_DISTROS" {
  default = jsonencode(default_distros())
}
variable "DISTROS" {
  default = ALL_DISTROS
  # default = jsonencode([default_distros()[length(default_distros()) - 1]]) # only latest
}
function "all_distros" {
  params = []
  result = jsondecode(ALL_DISTROS)
}
function "input_distros" {
  params = []
  result = flatten([jsondecode(DISTROS)])
}
function "matrix_distros" {
  params = []
  result = length(input_distros()) > 0 ? input_distros() : all_distros()
}

variable "ALL_QTCREATORS" {
  default = jsonencode(default_qtcreators())
}
variable "QTCREATORS" {
  default = ALL_QTCREATORS
  # default = jsonencode([default_qtcreators()[length(default_qtcreators()) - 1]]) # only latest
}
function "all_qtcreators" {
  params = []
  result = jsondecode(ALL_QTCREATORS)
}
function "input_qtcreators" {
  params = []
  result = flatten([jsondecode(QTCREATORS)])
}
function "latest_qtcreator_version" {
  params = []
  result = all_qtcreators()[length(all_qtcreators()) - 1].version
}
function "has_qtcreators" {
  params = []
  result = length(input_qtcreators()) > 0
}
function "matrix_qtcreators" {
  params = []
  result = has_qtcreators() ? input_qtcreators() : [{version: "", url: ""}]
}
function "is_latest_qtcreator_version" {
  params = [version]
  result = version != "" && latest_qtcreator_version() == version
}

variable "ALL_CLANGS" {
  default = jsonencode(default_clangs())
}
variable "CLANGS" {
  default = ALL_CLANGS
  # default = jsonencode([default_clangs()[length(default_clangs()) - 1]]) # only latest
}
function "all_clangs" {
  params = []
  result = jsondecode(ALL_CLANGS)
}
function "input_clangs" {
  params = []
  result = flatten([jsondecode(CLANGS)])
}
function "latest_clang_major" {
  params = []
  result = all_clangs()[length(all_clangs()) - 1].major
}
function "has_clangs" {
  params = []
  result = length(input_clangs()) > 0
}
function "is_clang_target" {
  params = [target]
  result = length(regexall("-clang(?:-|$)", target)) > 0
}
function "matrix_clangs" {
  params = [target]
  result = is_clang_target(target) && has_clangs() ? input_clangs() : [{major: "", source: ""}]
}
function "is_latest_clang_major" {
  params = [clang_major]
  # note: clang_major might be a number and types seems to get messed up
  result = clang_major != "" && "X${clang_major}" == "X${latest_clang_major()}"
}

variable "ALL_GCCS" {
  default = jsonencode(default_gccs())
}
variable "GCCS" {
  default = ALL_GCCS
  # default = jsonencode([default_gccs()[length(default_gccs()) - 1]]) # only latest
}
function "all_gccs" {
  params = []
  result = jsondecode(ALL_GCCS)
}
function "input_gccs" {
  params = []
  result = flatten([jsondecode(GCCS)])
}
function "latest_gcc_major" {
  params = []
  result = all_gccs()[length(all_gccs()) - 1].major
}
function "has_gccs" {
  params = []
  result = length(input_gccs()) > 0
}
function "is_gcc_target" {
  params = [target]
  result = length(regexall("-(?:gcc|libstdcpp)(?:-|$)", target)) > 0
}
function "matrix_gccs" {
  params = [target]
  result = is_gcc_target(target) && has_gccs() ? input_gccs() : [{major: "", source: "", distro: ""}]
}
function "is_latest_gcc_major" {
  params = [gcc_major]
  # note: gcc_major might be a number and types seems to get messed up
  result = gcc_major != "" && "X${gcc_major}" == "X${latest_gcc_major()}"
}

variable "ALL_QTS" {
  default = jsonencode(default_qts())
}
variable "QTS" {
  default = ALL_QTS
  # default = jsonencode([default_qts()[length(default_qts()) - 1]]) # only latest
}
function "all_qts" {
  params = []
  result = jsondecode(ALL_QTS)
}
function "input_qts" {
  params = []
  result = flatten([jsondecode(QTS)])
}
function "latest_qt_version" {
  params = []
  result = all_qts()[length(all_qts()) - 1].version
}
function "has_qts" {
  params = []
  result = length(input_qts()) > 0
}
function "is_qt_target" {
  params = [target]
  result = length(regexall("-qt", target)) > 0
}
function "matrix_qts" {
  params = [target]
  result = is_qt_target(target) && has_qts() ? input_qts() : [{version: "", arch: ""}]
}
function "is_latest_qt_version" {
  params = [qt_version]
  result = qt_version != "" && qt_version == latest_qt_version()
}
function "is_build_non_qt" {
  params = []
  result = has_qts() ? is_latest_qt_version(input_qts()[length(input_qts()) - 1].version) : true
}

function "targets" {
  params = []
  result = compact([
    has_qtcreators() && has_gccs() && is_build_non_qt() ? "qtcreator-gcc" : "",
    has_qtcreators() && has_gccs() && has_qts() ? "qtcreator-gcc-qt" : "",
    has_qtcreators() && has_clangs() && is_build_non_qt() ? "qtcreator-clang" : "",
    has_qtcreators() && has_clangs() && has_gccs() && is_build_non_qt() ? "qtcreator-clang-libstdcpp" : "",
    has_qtcreators() && has_clangs() && has_gccs() && has_qts() ? "qtcreator-clang-libstdcpp-qt" : ""
  ])
}
function "matrix" {
  params = []
  result = flatten([for target in targets() :
    flatten([for distro in matrix_distros() :
      flatten([for qtcreator in matrix_qtcreators() :
        flatten([for clang in matrix_clangs(target) :
          flatten([for gcc in matrix_gccs(target) :
            [for qt in matrix_qts(target) : {
              target: target,
              distro: (gcc.distro != "" ? gcc.distro : distro),
              qtcreator: qtcreator,
              clang: clang,
              gcc: gcc,
              qt: qt
            }]
          ])
        ])
      ])
    ])
  ])
}

function "latestTag" {
  params = [qtcreator_version, clang_major, gcc_major, qt_version]
  result = (is_latest_qtcreator_version(qtcreator_version)
    && (clang_major == "" || is_latest_clang_major(clang_major))
    && (gcc_major == "" || is_latest_gcc_major(gcc_major))
    && (qt_version == "" || is_latest_qt_version(qt_version)) ? "latest" : "")
}
function "versionTag" {
  params = [qtcreator_version, clang_major, gcc_major, qt_version]
  result = join("-", compact([qtcreator_version, clang_major, gcc_major, qt_version]))
}
function "tags" {
  params = [target, qtcreator_version, clang_major, gcc_major, qt_version]
  result = flatten([for tag in compact([versionTag(qtcreator_version, clang_major, gcc_major, qt_version), latestTag(qtcreator_version, clang_major, gcc_major, qt_version)]) : [
    "arbmind/${target}:${tag}",
    "ghcr.io/arbmind/${target}:${tag}"
  ]])
}
function "describeClang" {
  params = [major]
  result = major == "" ? "" : "Clang${major}"
}
function "describeGcc" {
  params = [target, major]
  result = major == "" ? "" : (is_clang_target(target) ? "LibStdC++${major}" : "GCC${major}")
}
function "describeQt" {
  params = [target, version]
  result = version == "" ? "" : "Qt ${version}"
}
function "description" {
  params = [target, distro, qtcreator_version, clang_major, gcc_major, qt_version]
  result = "Ubuntu ${distro} - ${join(" + ", compact(["QtCreator ${qtcreator_version}", describeClang(clang_major), describeGcc(target, gcc_major), describeQt(target, qt_version)]))}"
}
function "uniqueName" {
  params = [target, distro, qtcreator_version, clang_major, gcc_major, qt_version]
  result = join("-", compact([target, distro, replace(qtcreator_version, ".", "_"), clang_major, gcc_major, replace(qt_version, ".", "_")]))
}
target "default" {
  dockerfile = "Dockerfile"
  context = "./"
  target = matrix.target
  name = uniqueName(matrix.target, matrix.distro, matrix.qtcreator.version, matrix.clang.major, matrix.gcc.major, matrix.qt.version)
  tags = tags(matrix.target, matrix.qtcreator.version, matrix.clang.major, matrix.gcc.major, matrix.qt.version)
  matrix = {
    matrix = matrix()
  }
  args = {
    DISTRO = matrix.distro
    QTCREATOR_VERSION = matrix.qtcreator.version
    QTCREATOR_URL = matrix.qtcreator.url
    CLANG_MAJOR = matrix.clang.major
    CLANG_SOURCE = matrix.clang.source
    GCC_MAJOR = matrix.gcc.major
    GCC_SOURCE = matrix.gcc.source
    QT_VERSION = matrix.qt.version
    QT_ARCH = matrix.qt.arch
  }
  labels = {
    "org.opencontainers.image.source" = "https://github.com/arBmind/qtcreator-containers"
    Description = description(matrix.target, matrix.distro, matrix.qtcreator.version, matrix.clang.major, matrix.gcc.major, matrix.qt.version)
  }
}
