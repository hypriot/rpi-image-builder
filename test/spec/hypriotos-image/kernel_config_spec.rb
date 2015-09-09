Specinfra::Runner.run_command('modprobe configs')

describe command('zcat /proc/config.gz') do
  its(:stdout) { should match /CONFIG_KPROBES=y/ }
  its(:stdout) { should match /CONFIG_UPROBES=y/ }
  its(:stdout) { should match /CONFIG_HAVE_KPROBES=y/ }
  its(:stdout) { should match /CONFIG_EVENT_TRACING=y/ }
  its(:stdout) { should match /CONFIG_KPROBE_EVENT=y/ }
  its(:stdout) { should match /CONFIG_UPROBE_EVENT=y/ }
  its(:stdout) { should match /CONFIG_PROBE_EVENTS=y/ }
  its(:stdout) { should match /CONFIG_FTRACE=y/ }
  its(:stdout) { should match /CONFIG_FTRACE_SYSCALLS=y/ }
  its(:stdout) { should match /CONFIG_DYNAMIC_FTRACE=y/ }
  its(:stdout) { should match /CONFIG_HAVE_DYNAMIC_FTRACE=y/ }
  its(:exit_status) { should eq 0 }
end
