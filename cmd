[Python标准库]cmd——面向行的命令处理器
    作用：创建面向行的命令处理器。
    Python 版本：1.4 及以后版本
    cmd 模块包含一个公共类 Cmd，这个类要用作交互式 shell 和其他命令解释器的基类。默认情况下，它使用 readline 完成交互式提示处理、命令行编辑和命令完成。
处理命令
    用 Cmd 创建的命令 解释器使用一个循环从其输入读取所有行，进行解析，然后将命令分派到一个适当的命令处理程序（command handler）。输入行会解析为两部分：命令以及该行上的所有其他文本。如果用户输入 foo bar，而且解释器包含一个名为 do_foo() 的方法，则会调用这个方法并以“bar”作为其唯一参数。
    文件末尾（end-of-file）标志分派至 do_EOF()。如果一个命令处理程序返回 true 值，程序会妥善地退出。所以要提供一个简洁的方法退出解释器，就一定要实现 do_EOF()，并让它返回 True。
    这个简单的示例程序支持“greet”命令。

import cmd

class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""

	def do_greet(self, line):
		print "hello"

	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	HelloWorld().cmdloop()

    交互式地运行这个程序，可以展示如何分派命令，并显示 Cmd 中包含的一些特性。
    首先要注意的是命令提示语（Cmd）。这个提示语可以通过属性 prompt 来配置。如果由于一个命令处理器而改变了提示语，将使用新值来询问下一个命令。
    help 命令内置在 Cmd 中。如果没有提供参数，help 会显示可用命令的列表。如果输入包括一个命令，输入则更为详细，将只显示该命令的详细信息（如果有这个命令）。
    如果命令是 greet，会调用 do_greet() 来进行处理。
    对应一个命令，如果类中没有包含特定的命令处理器，会调用方法 default()，并以整个输入行作为参数。default() 的内置实现会报告一个错误。
    由于 do_EOF() 返回 True，键入 Ctrl-D 会使解释器退出。退出时不会打印换行，所以结果看上去有些乱。
命令参数
    这个例子做了一些改进，来消除存在的一些问题，并为 greet 命令增加帮助。

import cmd

class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""

	def do_greet(self, person):
		"""greet [person]
		Greet the named person"""
		if person:
			print "hi,", person
		else:
			print 'hi'

	def do_EOF(self, line):
		return True

	def postloop(self):
		print

if __name__ == '__main__':
	HelloWorld().cmdloop()

    增加到 do_greet() 的 docstring 会成为这个命令的帮助文本。输出显示了 greet 的一个可选参数 person。尽管这个参数对命令来说是可选的，但是命令和回调方法之间存在一个区别。方法总是有参数，不过有时这个值是一个空串。要由命令处理器来确定空参数是否合法，或者对命令做进一步的解析和处理。在这个例子中，如果提供了一个人名，就会提供个性化的欢迎词。
    不论用户是否指定参数，传递到命令处理器的值都不会包含命令本身。这会简化命令处理器中的解析，特别是在需要多个参数时。
现场帮助
    在前面的例子中，帮助文本的格式化还需要有所改进。由于它来自 docstring，所以保留了源文件中的缩进。可以修改源文件，删除多余的空白符，不过这会使应用代码看起来格式很糟糕。更好的解决方案是为 greet 命令实现一个帮助处理程序，名为 help_greet()。将调用这个帮助处理程序为指定的命令生成帮助文本。

import cmd

class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""

	def do_greet(self, person):
		if person:
			print "hi,", person
		else:
			print 'hi'

	def help_greet(self):
		print '\n'.join([ 'greet [person]',
						  'Greet the named person',
						  ])

	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	HelloWorld().cmdloop()

    在这个例子中，文本是静态的，不过得到了更好的格式化。还可以使用前面的命令状态将帮助文档的内容调整到当前上下文。
    要由帮助处理程序具体输出帮助消息，而不只是返回帮助文本在别处处理。
自动完成
    Cmd 利用处理器方法支持根据命令名实现命令完成。用户在输出提示符处按下 Tab 键就会触发这个完成功能。可能有多个完成候选时，按下两次 Tab 键会显示一个选项列表。
    一旦命令已知，可以由带 complete_ 前缀的方法来处理参数完成。这就允许新的完成处理器使用任意的规则组装一个完成候选列表（也就是说，可以查询数据库，或者查看一个文件或文件系统上的目录）。在这里，程序硬编码编写了一个“朋友”集合，与命名或匿名的陌生人相比，这些朋友会收到更亲切的欢迎。实际程序可能会在某个地方保存这个列表，读取一次后将内容缓存，以便在需要时查看。

import cmd

class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""

	FRIENDS = [ 'Alice', 'Adam', 'Barbara', 'Bob' ]

	def do_greet(self, person):
		"Greet the person"
		if person and person in self.FRIENDS:
			greeting = 'hi, %s!' % person
		elif person:
			greeting = 'hello, ' + person
		else:
			greeting = 'hello'
		print greeting

	def complete_greet(self, text, line, begidx, endidx):
		if not text:
			completions = self.FRIENDS[:]
		else:
			completions = [f for f in self.FRIENDS if f.startswith(text)]
		return completions

	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	HelloWorld().cmdloop()

    如果有输入文本，complete_greet() 会返回一个匹配的朋友列表。否则，返回整个朋友列表。如果给定的名字不在朋友列表中，会给出正式的欢迎词。
覆盖基类方法
    Cmd 包括的很多方法可以覆盖为 hook，用来采取动作或改变基类行为。下面这个例子并不详尽，不过其中包括很多通常很有用的方法。

import cmd

class Illustrate(cmd.Cmd):
	"Illustrate the base class method use."

	def cmdloop(self, intro=None):
		print 'cmdloop(%s)' % intro
		return cmd.Cmd.cmdloop(self, intro)

	def preloop(self):
		print 'preloop()'

	def postloop(self):
		print 'postloop()'

	def parseline(self, line):
		print 'parseline(%s) =>' % line,
		ret = cmd.Cmd.parseline(self, line)
		print ret
		return ret

	def onecmd(self, s):
		print 'onecmd(%s)' % s
		return cmd.Cmd.onecmd(self, s)

	def emptyline(self):
		print 'emptyline()'
		return cmd.Cmd.emptyline(self)

	def default(self, line):
		print 'default(%s)' % line
		return cmd.Cmd.default(self, line)

	def precmd(self, line):
		print 'precmd(%s)' % line
		return cmd.Cmd.precmd(self, line)

	def postcmd(self, stop, line):
		print 'postcmd(%s, %s)' % (stop, line)
		return cmd.Cmd.postcmd(self, stop, line)

	def do_greet(self, line):
		print 'hello,', line

	def do_EOF(self, line):
		"Exit"
		return True

if __name__ == '__main__':
	Illustrate().cmdloop('Illustrating the methods of cmd.Cmd')

    cmdloop() 是解释器的主处理循环。通常没有必要覆盖这个循环，因为可以使用 preloop() 和 postloop() hook。
    每次 cmdloop() 迭代都会调用 onecmd()， 将命令分派到其处理器。实际输入行用 parseline() 解析来创建一个元组，其中包含命令和该行上的其余部分。
    如果这一行为空，则调用 emptyline()。默认实现会再次运行前面的命令。如果这一行包含一个命令，将调用一个 precmd()，然后查看并调用处理器。如果没有找到，则调用 default()。最后调用 postcmd()。
通过属性配置 Cmd
    除了前面描述的方法，还有很多属性可以用来控制命令解释器。可以把 prompt 设置为一个字符串，每次要求用户输入一个新命令时就显示这个字符串。intro 是程序开始时打印的“欢迎”消息。cmdloop() 取对应这个值的一个参数，或者也可以在类上直接设置。打印帮助时，可以用 doc_header、misc_header、undoc_header 和 ruler 属性对输出进行格式化。

import cmd

class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""

	prompt = 'prompt: '
	intro = "Simple command processor example."

	doc_header = 'doc_header'
	misc_header = 'misc_header'
	undoc_header = 'undoc_header'

	ruler = '-'

	def do_prompt(self, line):
		"Change the interactive prompt"
		self.prompt = line + ': '

	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	HelloWorld().cmdloop()

    这个示例类显示了一个命令处理器，允许用户控制交互式会话的提示语。
运行 shell 命令
    作为对标准命令处理的补充，Cmd 包括两个特殊的命令前缀。问号（?）等价于内置的 help 命令，可以用同样的方式使用。感叹号（!）对应 do_shell()，它要“作为外壳”运行其他命令，如下例所示。

import cmd
import subprocess

class ShellEnable(cmd.Cmd):

	last_output = ''

	def do_shell(self, line):
		"Run a shell command"
		print "running shell command:", line
		sub_cmd = subprocess.Popen(line, shell=True, stdout=subprocess.PIPE)
		output = sub_cmd.communicate()[0]
		print output
		self.last_output = output

	def do_echo(self, line):
		"""Print the input, replacing '$out' with
		the output of the last shell command.
		"""
		# Obviously not robust
		print line.replace('$out', self.last_output)

	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	ShellEnable().cmdloop()

    这个 echo 命令实现将其参数中的串 $out 替换为前面 shell 命令的输出。
候选输入
    Cmd() 的默认模式是通过 readline 库与用户交互，不过也可以使用标准 UNIX shell 重定向为标准输入传递一系列命令。
    要让程序直接读取一个脚本文件，可能还需要另外一些修改。因为 readline 与终端 /tty 设备交互，而不是与标准输入流交互，从文件读取脚本时应当将其禁用。另外，为了避免打印多余的提示语，可以把提示语设置为一个空串。下面的例子显示了如何打开一个文件，并作为输入将它传递到 HelloWorld 例子的一个修改版本。

import cmd

class HelloWorld(cmd.Cmd):
	"""Simple command processor example."""

	# Disable rawinput module use
	use_rawinput = False

	# Do not show a prompt after each command read
	prompt = ''

	def do_greet(self, line):
		print "hello,", line

	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	import sys
	with open(sys.argv[1], 'rt') as input:
		HelloWorld(stdin=input).cmdloop()

    将 use_rawinput 设置为 False，prompt 设置为一个空串，现在可以在这个输入文件上调用这个脚本。

greet
greet Alice and Bob

sys.argv 的命令
    也可以将程序的命令行参数处理为命令，提供给解释器类，而不是从控制台或文件读取命令。要使用命令行参数，可以直接调用 onecmd()，如下例所示。

import cmd
import subprocess

class InteractiveOrCommandLine(cmd.Cmd):
	"""Accepts commands via the normal interactive
	prompt or on the command line.
	"""

	def do_greet(self, line):
		print 'hello,', line

	def do_EOF(self, line):
		return True

if __name__ == '__main__':
	import sys
	if len(sys.argv) > 1:
		InteractiveOrCommandLine().onecmd(' '.join(sys.argv[1:]))
	else:
		InteractiveOrCommandLine().cmdloop()

    由于 onecmd() 取一个字符串作为输入，在参数传入之前，需要把程序的参数连接起来。
