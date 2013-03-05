Index: sys/conf/newvers.sh
--- sys/conf/newvers.sh	23 May 2006 04:09:11 -0000
+++ sys/conf/newvers.sh	27 Aug 2006 01:55:22 -0000
@@ -33,6 +33,9 @@
 TYPE="FreeBSD"
 REVISION="5.5"
 BRANCH="RELEASE"
+if [ "X${BRANCH_OVERRIDE}" != "X" ]; then
+	BRANCH=${BRANCH_OVERRIDE}
+fi
 RELEASE=5.5-RELEASE
 VERSION="${TYPE} ${RELEASE}"
 
@@ -85,10 +88,14 @@
 i=`${MAKE:-make} -V KERN_IDENT`
 cat << EOF > vers.c
 $COPYRIGHT
-char sccs[] =  "@(#)${VERSION} #${v}: ${t}";
-char version[] = "${VERSION} #${v}: ${t}\\n    ${u}@${h}:${d}\\n";
+#define SCCSSTR "@(#)${VERSION} #${v}: ${t}"
+#define VERSTR "${VERSION} #${v}: ${t}\\n    ${u}@${h}:${d}\\n"
+#define RELSTR "${RELEASE}"
+
+char sccs[sizeof(SCCSSTR) > 128 ? sizeof(SCCSSTR) : 128] = SCCSSTR;
+char version[sizeof(VERSTR) > 256 ? sizeof(VERSTR) : 256] = VERSTR;
 char ostype[] = "${TYPE}";
-char osrelease[] = "${RELEASE}";
+char osrelease[sizeof(RELSTR) > 32 ? sizeof(RELSTR) : 32] = RELSTR;
 int osreldate = ${RELDATE};
 char kern_ident[] = "${i}";
 EOF
