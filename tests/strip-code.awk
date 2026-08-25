# strip-code.awk: drop <pre>...</pre> regions and inline <code>...</code>
# spans from built HTML.
#
# Several posts document the very syntax the output-hygiene checks look for --
# blogs/cms-pandoc, for one, shows pandoc template conditionals inside a code
# block. Without this, a post explaining $if(...)$ is indistinguishable from a
# page leaking it.
{
  line = $0
  if (inpre) {
    if (line ~ /<\/pre>/) { inpre = 0; sub(/^.*<\/pre>/, "", line) } else { next }
  }
  gsub(/<code[^>]*>[^<]*<\/code>/, "", line)
  if (line ~ /<pre/) { sub(/<pre.*$/, "", line); inpre = 1 }
  print line
}
