<#
.SYNOPSIS
 A local, custom, highly integrated, commandline, personal task manager
#>

"
 _     _____  ___   _____  _   __    ___  ___  ___   _____  _____  _____ ______      _
| |   |_   _|/ _ \ /  ___|| | / /    |  \/  | / _ \ /  ___||_   _||  ___|| ___ \    | |
| |     | | / /_\ \\ '--. | |/ /     | .  . |/ /_\ \\ '--.   | |  | |__  | |_/ /    | |
| |     | | |  _  | '--. \|    \     | |\/| ||  _  | '--. \  | |  |  __| |    /     | |
| |     | | | | | |/\__/ /| |\  \    | |  | || | | |/\__/ /  | |  | |___ | |\ \     | |
| |     \_/ \_| |_/\____/ \_| \_/    \_|  |_/\_| |_/\____/   \_/  \____/ \_| \_|    | |
| |_________________________________________________________________________________| |
|_____________________________________________________________________________________|"
$task_file = join-path $PSScriptRoot "\TaskList.txt"
$finished_tasks_file = join-path $PSScriptRoot "FinishedTaskList.txt"
$notes_dir = join-path $PSScriptRoot "TaskNotes"

# Start functions Block

function Enter-WTasks
{
  waid_ls.ps1
}

function View-CurrentTask{
  $tasks = Select-String -path $task_file -pattern "- DONE" -NotMatch | %{$_.Line}
  $fst = $tasks | Select-Object -first 1
  if($fst -AND (!$fst.Contains("- DONE -")))
  {
    "Current Task:"
    write-host "----------$fst----------" -foreground "Yellow"
  }else{
    write-host "No Current Task" -foreground "Yellow"
  }
}

function New-Task
{
  #Create a new task
  $newTask = Read-Host "Please Enter your new Task"
      
  #asking about the status of this new task
  $newtask_question = "Is this your current task?"
  $newtask_explination = $null
  $newtask_yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Yes to '$newtask_question'"
  $newtask_no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "No to '$newtask_question'"
  $newtask_finished = New-Object System.Management.Automation.Host.ChoiceDescription "&Finished", "Task is already finished"
  $newtask_options = [System.Management.Automation.Host.ChoiceDescription[]]($newtask_yes, $newtask_no, $newtask_finished)
  $newtask_choice = $host.ui.PromptForChoice($newtask_question, $newtask_explination, $newtask_options, 0)

  #I found that many times I wanted the task to be the current task.
  if($newtask_choice -eq 0) #answered yes
  {
    Add-Content $task_file -value $newTask

    $origLines = type $task_file

    #This is an artificat from when the - DONE - stuff was still in the same file
    $tasks = @(Select-String -path $task_file -pattern "- DONE" -NotMatch | ForEach-Object{$_.Line})
    $index = $tasks.Length-1

    $selectedTask = $tasks[$index]
    $escaped = [regex]::Escape($tasks[$index])

    $otherLines = $origLines | %{if(!$_.Equals($selectedTask)){$_}} 
        
    $tasks[$index] | out-file $task_file 
    #make it so that this writes out every line that isn't that first one
    $otherLines | out-file $task_file -append
  }
  elseif($newtask_choice -eq 2)
  { 
    # I found that many times I wanted to auto finish a new task
    # This is useful for book keeping of thing I forgot to add
	
    $waid = waid
    $date = (Get-Date).ToString()
    add-content $waid "$newTask - DONE - $date"
    add-content $finished_tasks_file "$newTask - DONE - $date"
  }
  else #default / just add it to the end of the list
  {
    Add-Content $task_file -value $newTask
  }
  View-CurrentTask
}

# Sometimes a task requires some notes to get completed
# Create or view existing notes with this function
function View-Notes
{
  $firstLine = Get-Content $task_file | Select-Object -first 1
  $hash = $firstline.ToString().GetHashCode().ToString("X")
  $noteFile = $notes_dir + "\" + "N" + $hash + ".ls"
      
  if(-NOT(test-path $noteFile)){
    $firstline | out-file $noteFile
  }
      
  emacs $noteFile
  Remove-Item ($notes_dir+"\*~")
}

#Finish task and add to the daily notes in waid
function Complete-Task
{
  #decided to move the finished stuff to their own file.

  "Task Completed!"
  ""
  $firstLine = Get-Content $task_file | Select-Object -first 1
  $newContent = Get-Content $task_file | Select-Object -skip 1
  $newContent | out-file $task_file
  $date = (Get-Date).ToString()
  add-content $finished_tasks_file "$firstLine - DONE - $date"
  View-CurrentTask

  $waid = waid
  add-content $waid "$firstLine - DONE - $date"
}

#Sets user selected task to active tasks
function Set-Task
{
  $origLines = type $task_file

  #This is an artificat from when the - DONE - stuff was still in the same file
  $tasks = @(Select-String -path $task_file -pattern "- DONE" -NotMatch | %{$_.Line})
  $tasks | %{$i=0}{"[$i] $_";$i++}
  $index = read-host "Enter Task Index"

  $selectedTask = $tasks[$index]
  $escaped = [regex]::Escape($tasks[$index])

  $otherLines = $origLines | %{if(!$_.Equals($selectedTask)){$_}} 
      
  $tasks[$index] | out-file $task_file 
  #make it so that this writes out every line that isn't that first one
  $otherLines | out-file $task_file -append
  View-CurrentTask
}

# End Functions Block


#Start of Main

if($FancyGUI){FancyGUI;exit}

""
"Priorities"

Priorities
" _____________________________________________________________________________________
|_____________________________________________________________________________________|"

View-CurrentTask

$optionVals = @("&New Task", "&Edit", "&View Notes", "&Finish Current Task", "&Set Current Task", "&WTasks", "&Close")
$continue = $True
$title = ""
$smess = "What would you like to do?"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($optionVals)

while($continue)
{
  $choice = $host.ui.PromptForChoice($title, $smess, $options, 0) 

  switch($choice)
  {
    0{ #NEW TASK
      New-Task
    }
    1{ #EDIT TASK FILE
      vi $task_file
    }
    2{ #VIEW NOTES
      View-Notes
    }
    3{ #FINISH CURRENT TASK
      Complete-Task
    }
    4{ #SET CURRENT TASK
      Set-Task
    }
    5{ #WTasks 
      Enter-WTasks
    }
    6{ #CLOSE PROGRAM / EXIT SCRIPT
      $continue = $False
    }
    #DEFAULT - ask quesiton again
  }
}
