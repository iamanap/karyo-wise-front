const String tempAppFolder = 'KaryoWise';
String getChromosomeLabelByIndex(index) {
  return switch (index) { 23 => 'X', 24 => 'Y', _ => (index).toString() };
}
