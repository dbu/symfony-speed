<?php

namespace Dbu\Bundle\CoreBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\Request;
use Dbu\Bundle\CoreBundle\Entity\Comment;

class CommentsController extends Controller
{
    const FILE = '/tmp/comments';

    public function commentsAction()
    {
        return $this->render('DbuCoreBundle:Comments:comments.html.twig', array(
            'comments' => $this->getComments(),
        ));
    }

    public function formAction()
    {
        return $this->render('DbuCoreBundle:Comments:form.html.twig', array(
            'form' => $this->getForm()->createView(),
        ));
    }

    public function postAction(Request $request)
    {
        $form = $this->getForm();
        $form->bindRequest($request);

        if ($form->isValid()) {
            $comments = $this->getComments();
            $comments[] = $form->getData();
            if (! file_put_contents(self::FILE, serialize($comments))) {
                die('failed to write the data file');
            }

            // invalidate the varnish cache of home page so the new comment is shown
            $varnish = $this->container->get('liip_cache_control.varnish');
            $varnish->invalidatePath($this->generateUrl('home'));

            return $this->redirect($this->generateUrl('home'));
        }
    }

    private function getForm()
    {
        $comment = new Comment();
        $security = $this->get('security.context');
        if ($security->isGranted('IS_AUTHENTICATED_FULLY')) {
            $comment->author = $security->getToken()->getUser()->getUsername();
        }

        $form = $this->createFormBuilder($comment)
            ->add('author')
            ->add('text')
            ->getForm();

        return $form;
    }

    private function getComments()
    {
        if (! file_exists(self::FILE)) {
            return array();
        }
        return unserialize(file_get_contents(self::FILE));
    }
}
