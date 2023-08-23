locals {
  # network labels for easy reading (and 'all' for consistency)
  icmp     = "1"
  tcp      = "6"
  udp      = "17"
  anyproto = "all"
  anywhere = "0.0.0.0/0"

  # icmp labels
  icmp_types = {
    echo_reply    = 0
    dest_unreach  = 3
    source_quench = 4
    echo_request  = 8
    time_exceeded = 11
  }
}