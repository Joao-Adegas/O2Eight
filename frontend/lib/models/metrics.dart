class DayMetric {
  final String label;
  final double value;

  const DayMetric(this.label, this.value);
}

class TriggerMetric {
  final String label;
  final int count;
  final int pct;

  const TriggerMetric(this.label, this.count, this.pct);
}

class HourRisk {
  final String hour;
  final int risk;

  const HourRisk(this.hour, this.risk);
}

class Milestone {
  final String time;
  final String label;
  final bool done;

  const Milestone(this.time, this.label, this.done);
}

class ClusterData {
  final String name;
  final int usersK;
  final int success;

  const ClusterData(this.name, this.usersK, this.success);
}
