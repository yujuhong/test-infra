/*
Copyright 2016 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"github.com/Sirupsen/logrus"

	"k8s.io/test-infra/prow/github"
	"k8s.io/test-infra/prow/plugins"
)

// EventAgent pulls events off of the queues and dispatches to the relevant
// plugins.
type EventAgent struct {
	Plugins *plugins.PluginAgent

	PullRequestEvents  <-chan github.PullRequestEvent
	IssueCommentEvents <-chan github.IssueCommentEvent
}

// Start starts listening for events. It does not block.
func (ea *EventAgent) Start() {
	go func() {
		for pr := range ea.PullRequestEvents {
			go ea.handlePullRequestEvent(pr)
		}
	}()
	go func() {
		for ic := range ea.IssueCommentEvents {
			go ea.handleIssueCommentEvent(ic)
		}
	}()
}

func (ea *EventAgent) handlePullRequestEvent(pr github.PullRequestEvent) {
	l := logrus.WithFields(logrus.Fields{
		"org":  pr.PullRequest.Base.Repo.Owner.Login,
		"repo": pr.PullRequest.Base.Repo.Name,
		"pr":   pr.Number,
		"url":  pr.PullRequest.HTMLURL,
	})
	l.Infof("Pull request %s.", pr.Action)
	for p, h := range ea.Plugins.PullRequestHandlers(pr.PullRequest.Base.Repo.FullName) {
		if err := h(ea.Plugins, pr); err != nil {
			l.WithError(err).WithField("plugin", p).Error("Error handling PullRequestEvent.")
		}
	}
}

func (ea *EventAgent) handleIssueCommentEvent(ic github.IssueCommentEvent) {
	l := logrus.WithFields(logrus.Fields{
		"org":    ic.Repo.Owner.Login,
		"repo":   ic.Repo.Name,
		"pr":     ic.Issue.Number,
		"author": ic.Comment.User.Login,
		"url":    ic.Comment.HTMLURL,
	})
	l.Infof("Issue comment %s.", ic.Action)
	for p, h := range ea.Plugins.IssueCommentHandlers(ic.Repo.FullName) {
		if err := h(ea.Plugins, ic); err != nil {
			l.WithError(err).WithField("plugin", p).Error("Error handling IssueCommentEvent.")
		}
	}
}
