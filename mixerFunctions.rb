
def execute(command,retval=false)
	puts "\n==========================\nExecuting: "+command+"\n==========================\n";
	if !retval
		return `#{command}`
	else
		return system(command)
	end
end

def findName(mixerFile, name)
	if File.exists? mixerFile
		fh = File.open(mixerFile)
		fh.each_with_index{|line, index|
			if line.length > 1 
				line = Marshal.load(line)
				if line[:name] == name
					return {:line=>line,:index=>index}
				end
			end
		}
		fh.close
	end
	return false
end
def addMixLine(mixerFile, mix)
	found = findName(mixerFile, mix[:name])
	
	line = Marshal.dump(mix)
	
	if found
		replaceLine(mixerFile, found[:index], line)
	else
		fh = File.open(mixerFile,'a')
		fh.puts(line)
		fh.close
	end
end
def replaceLine(file, lineNumber, contents)
	fh = File.open(file)
	tmpFile = '/tmp/thoughtpush.tools.replaceLine.tmp'
	fhTemp = File.open(tmpFile,'w')
	
	index = 0
	replaced = false;
	fh.each_with_index{|line,index|
		if index == lineNumber
			replaced = true
			fhTemp.puts(contents)
		else
			fhTemp.puts(line)
		end
	}
	rm(file)
	mv(tmpFile,file)
	return replaced
end
def deleteLines(file, lines)
	lineHash = {}
	lines.each{|line|
		lineHash[line.to_i] = true
	}
	
	fh = File.open(file)
	tmpFile = '/tmp/thoughtpush.tools.deleteLines.tmp'
	fhTemp = File.open(tmpFile,'w')
	
	fh.each_with_index{|line,index|
		if !lineHash[index]
			fhTemp.puts(line)
		end
	}
	rm(file)
	mv(tmpFile,file)
end